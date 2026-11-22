#ifndef SERVICES_NETWORK_ZEE_REQUEST_POLICY_H_
#define SERVICES_NETWORK_ZEE_REQUEST_POLICY_H_

class GURL;

namespace net {
class URLRequest;
}

namespace network::zee {

// Whether Zee keeps `request`, about to load `url`, from reaching Google.
//
// Pages and the person may load anything. The browser's own requests reach a
// Google-owned host only for the services Zee keeps, each named by its
// traffic annotation and the hosts it uses. Any other browser request to
// Google fails, including one a later Chromium adds: the list fails closed.
// ForkMaintenance.md describes the review each milestone needs.
bool BlocksRequest(const net::URLRequest& request, const GURL& url);

}  // namespace network::zee

#endif  // SERVICES_NETWORK_ZEE_REQUEST_POLICY_H_
