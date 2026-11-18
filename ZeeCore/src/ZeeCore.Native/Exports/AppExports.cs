using System.Collections.Concurrent;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

using ZeeCore.Application;
using ZeeCore.Contracts;

namespace ZeeCore.Native;

/// A byte buffer the core allocated for the caller, released with `zee_buffer_free`.
[StructLayout(LayoutKind.Sequential)]
public unsafe struct ZeeBuffer {
    public byte* Bytes;
    public nuint Length;
}

public static unsafe partial class Exports {
    #region Variables

    private static readonly ConcurrentDictionary<ulong, ZeeApp> Apps = new();
    /// Answers the queries that read no state, which need no app.
    private static readonly StandaloneAnswers Standalone = new();

    #endregion

    #region Actions - Native exports

    [UnmanagedCallersOnly(EntryPoint = "zee_app_create", CallConvs = [typeof(CallConvCdecl)])]
    public static int AppCreate(byte* fingerprint, nuint length, byte* configuration, nuint configurationLength,
        ulong* app, ZeeBuffer* rejection) {
        if (app == null) return CoreStatus.InvalidArgument;
        *app = 0;
        return Configured(fingerprint, length, configuration, configurationLength, rejection, settings => {
            var created = new ZeeApp(settings);
            var id = checked((ulong)Interlocked.Increment(ref nextHandle));
            if (!Apps.TryAdd(id, created)) {
                created.Dispose();
                return CoreStatus.InternalError;
            }
            *app = id;
            return CoreStatus.Ok;
        });
    }

    /// Replaces the session file in the configured directory with its
    /// recovery checkpoint. No app may have the directory open.
    [UnmanagedCallersOnly(EntryPoint = "zee_app_restore", CallConvs = [typeof(CallConvCdecl)])]
    public static int AppRestore(byte* fingerprint, nuint length, byte* configuration, nuint configurationLength,
        ZeeBuffer* rejection) =>
        Configured(fingerprint, length, configuration, configurationLength, rejection, settings => {
            ZeeApp.RestoreRecoveryCheckpoint(settings);
            return CoreStatus.Ok;
        });

    /// Saves what the app's session file still owes and closes it. Clear the
    /// wake callback first.
    [UnmanagedCallersOnly(EntryPoint = "zee_app_destroy", CallConvs = [typeof(CallConvCdecl)])]
    public static int AppDestroy(ulong app) {
        try {
            if (!Apps.TryRemove(app, out var zee)) return CoreStatus.InvalidHandle;
            ForgetEngines(app);
            zee.Dispose();
            return CoreStatus.Ok;
        } catch { return CoreStatus.InternalError; }
    }

    [UnmanagedCallersOnly(EntryPoint = "zee_app_set_wake", CallConvs = [typeof(CallConvCdecl)])]
    public static int AppSetWake(ulong app, delegate* unmanaged[Cdecl]<nint, void> callback, nint context) {
        try {
            if (!Apps.TryGetValue(app, out var zee)) return CoreStatus.InvalidHandle;
            var function = (nint)callback;
            zee.SetWake(function == 0 ? null : () => Wake(function, context));
            return CoreStatus.Ok;
        } catch { return CoreStatus.InternalError; }
    }

    [UnmanagedCallersOnly(EntryPoint = "zee_app_end_turn", CallConvs = [typeof(CallConvCdecl)])]
    public static int AppEndTurn(ulong app) {
        try {
            if (!Apps.TryGetValue(app, out var zee)) return CoreStatus.InvalidHandle;
            zee.EndTurn();
            return CoreStatus.Ok;
        } catch { return CoreStatus.InternalError; }
    }

    [UnmanagedCallersOnly(EntryPoint = "zee_app_settle_sync", CallConvs = [typeof(CallConvCdecl)])]
    public static int AppSettleSync(ulong app) {
        try {
            if (!Apps.TryGetValue(app, out var zee)) return CoreStatus.InvalidHandle;
            zee.SettleSync();
            return CoreStatus.Ok;
        } catch { return CoreStatus.InternalError; }
    }

    [UnmanagedCallersOnly(EntryPoint = "zee_app_drain", CallConvs = [typeof(CallConvCdecl)])]
    public static int AppDrain(ulong app, ZeeBuffer* output) {
        if (output == null) return CoreStatus.InvalidArgument;
        *output = default;
        try {
            if (!Apps.TryGetValue(app, out var zee)) return CoreStatus.InvalidHandle;
            var changes = zee.Drain();
            var writer = new WireWriter();
            writer.WriteCount(changes.Count);
            foreach (var change in changes) ContractCodec.WriteChange(writer, change);
            *output = Allocate(writer.WrittenSpan);
            return CoreStatus.Ok;
        } catch { return CoreStatus.InternalError; }
    }

    [UnmanagedCallersOnly(EntryPoint = "zee_app_dispatch", CallConvs = [typeof(CallConvCdecl)])]
    public static int AppDispatch(ulong app, byte* intent, nuint length, ZeeBuffer* output) =>
        Call(app, intent, length, output, ContractCodec.MaximumIntentBytes, (zee, reader, writer) => {
            var changes = zee.Send(Finished(ContractCodec.ReadIntent(reader), reader));
            writer.WriteCount(changes.Count);
            foreach (var change in changes) ContractCodec.WriteChange(writer, change);
        });

    [UnmanagedCallersOnly(EntryPoint = "zee_app_query", CallConvs = [typeof(CallConvCdecl)])]
    public static int AppQuery(ulong app, byte* query, nuint length, ZeeBuffer* output) =>
        Call(app, query, length, output, ContractCodec.MaximumQueryBytes, (zee, reader, writer) =>
            ContractCodec.WriteAnswer(writer, zee, Finished(ContractCodec.ReadQuery(reader), reader)));

    /// The address of the app's content filter slot, for an engine binding that
    /// checks each request itself with `zee_content_filter_slot_check`, which
    /// the core's library exports beside this. The first call compiles the
    /// filter on a worker; until it is in force the slot allows every request.
    [UnmanagedCallersOnly(EntryPoint = "zee_app_content_filter_slot", CallConvs = [typeof(CallConvCdecl)])]
    public static int AppContentFilterSlot(ulong app, nint* slot) {
        if (slot == null) return CoreStatus.InvalidArgument;
        *slot = 0;
        try {
            if (!Apps.TryGetValue(app, out var zee)) return CoreStatus.InvalidHandle;
            *slot = zee.ContentFilterSlot();
            return CoreStatus.Ok;
        } catch {
            return CoreStatus.InternalError;
        }
    }

    /// Answers a query that reads no state without an app, for a host that
    /// has none yet or asks from code that holds none.
    [UnmanagedCallersOnly(EntryPoint = "zee_core_answer", CallConvs = [typeof(CallConvCdecl)])]
    public static int CoreAnswer(byte* fingerprint, nuint fingerprintLength, byte* query, nuint length, ZeeBuffer* output) {
        if (output == null) return CoreStatus.InvalidArgument;
        *output = default;
        if (fingerprint == null && fingerprintLength != 0) return CoreStatus.InvalidArgument;
        if (fingerprintLength != (nuint)ContractCodec.Fingerprint.Length
            || !new ReadOnlySpan<byte>(fingerprint, (int)fingerprintLength).SequenceEqual(ContractCodec.Fingerprint))
            return CoreStatus.VersionMismatch;
        return Run(query, length, output, ContractCodec.MaximumQueryBytes, (reader, writer) =>
            ContractCodec.WriteAnswer(writer, Standalone, Finished(ContractCodec.ReadQuery(reader), reader)));
    }

    /// Clears the buffer's bytes before it releases them, since an answer may
    /// hold passwords the core read or wrote for the caller.
    [UnmanagedCallersOnly(EntryPoint = "zee_buffer_free", CallConvs = [typeof(CallConvCdecl)])]
    public static void BufferFree(ZeeBuffer* buffer) {
        if (buffer == null) return;
        if (buffer->Bytes != null) NativeMemory.Clear(buffer->Bytes, buffer->Length);
        NativeMemory.Free(buffer->Bytes);
        *buffer = default;
    }

    #endregion

    #region Actions - Messages

    /// Checks the schema fingerprint, decodes one `AppConfiguration` and runs
    /// `body` with it, answering the encoded rejection with REJECTED.
    private static int Configured(byte* fingerprint, nuint length, byte* configuration, nuint configurationLength,
        ZeeBuffer* rejection, Func<AppConfiguration, int> body) {
        if (rejection == null) return CoreStatus.InvalidArgument;
        *rejection = default;
        if (fingerprint == null && length != 0 || configuration == null && configurationLength != 0) return CoreStatus.InvalidArgument;
        if (configurationLength > MessageLimitAttribute.DefaultBytes) return CoreStatus.LimitExceeded;
        try {
            if (length != (nuint)ContractCodec.Fingerprint.Length
                || !new ReadOnlySpan<byte>(fingerprint, (int)length).SequenceEqual(ContractCodec.Fingerprint))
                return CoreStatus.VersionMismatch;
            var reader = new WireReader(new ReadOnlySpan<byte>(configuration, (int)configurationLength).ToArray());
            var settings = Finished(ContractCodec.ReadAppConfiguration(reader), reader);
            try {
                return body(settings);
            } catch (Rejected refused) {
                var writer = new WireWriter();
                ContractCodec.WriteRejection(writer, refused.Rejection);
                *rejection = Allocate(writer.WrittenSpan);
                return CoreStatus.Rejected;
            }
        } catch (WireFormatException) {
            return CoreStatus.InvalidMessage;
        } catch {
            return CoreStatus.InternalError;
        }
    }

    /// Decodes one message, runs it and hands the caller the encoded answer, or
    /// the encoded rejection with REJECTED. A message longer than its type's
    /// limit, which its leading tag names, is refused before it is read.
    private static int Call(ulong app, byte* input, nuint length, ZeeBuffer* output, Func<int, int> maximumBytes,
        Action<ZeeApp, WireReader, WireWriter> run) {
        if (output == null) return CoreStatus.InvalidArgument;
        *output = default;
        if (!Apps.TryGetValue(app, out var zee)) return CoreStatus.InvalidHandle;
        return Run(input, length, output, maximumBytes, (reader, writer) => run(zee, reader, writer));
    }

    /// Decodes one message and runs it, as `Call` does, without an app. The
    /// core's copies of the message and its answer are cleared once the
    /// caller holds the answer, since either may hold passwords.
    private static int Run(byte* input, nuint length, ZeeBuffer* output, Func<int, int> maximumBytes, Action<WireReader, WireWriter> run) {
        if (input == null && length != 0) return CoreStatus.InvalidArgument;
        int tag = WireReader.PeekTag(new ReadOnlySpan<byte>(input, (int)Math.Min(length, (nuint)WireReader.MaximumTagBytes)));
        if (length > (nuint)maximumBytes(tag)) return CoreStatus.LimitExceeded;
        byte[] message = new ReadOnlySpan<byte>(input, (int)length).ToArray();
        var writer = new WireWriter();
        try {
            var reader = new WireReader(message);
            try {
                run(reader, writer);
            } catch (Rejected rejected) {
                var rejection = new WireWriter();
                ContractCodec.WriteRejection(rejection, rejected.Rejection);
                *output = Allocate(rejection.WrittenSpan);
                return CoreStatus.Rejected;
            }
            *output = Allocate(writer.WrittenSpan);
            return CoreStatus.Ok;
        } catch (WireFormatException) {
            return CoreStatus.InvalidMessage;
        } catch {
            return CoreStatus.InternalError;
        } finally {
            Array.Clear(message);
            writer.Clear();
        }
    }

    private static void Wake(nint callback, nint context) => ((delegate* unmanaged[Cdecl]<nint, void>)callback)(context);

    /// A decoded message must use every byte it arrived with.
    private static T Finished<T>(T message, WireReader reader) {
        reader.EnsureEnd();
        return message;
    }

    private static ZeeBuffer Allocate(ReadOnlySpan<byte> bytes) {
        var memory = (byte*)NativeMemory.Alloc((nuint)Math.Max(bytes.Length, 1));
        bytes.CopyTo(new Span<byte>(memory, bytes.Length));
        return new ZeeBuffer { Bytes = memory, Length = (nuint)bytes.Length };
    }

    #endregion
}
