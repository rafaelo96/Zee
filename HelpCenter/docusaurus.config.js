const {themes: prismThemes} = require('prism-react-renderer');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Zee Help',
  tagline: 'Help articles for Zee.',
  favicon: 'img/zee-logo.svg',
  url: 'https://zee.dev',
  baseUrl: '/guides/',
  organizationName: 'rafaelo96',
  projectName: 'Zee-Website',
  trailingSlash: true,
  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },
  plugins: [require.resolve('./plugins/help-search-index')],
  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: require.resolve('./sidebars.js'),
          breadcrumbs: true,
          showLastUpdateAuthor: false,
          showLastUpdateTime: false,
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
        sitemap: {
          changefreq: 'weekly',
          priority: 0.7,
        },
      },
    ],
  ],
  themeConfig: {
    image: 'https://zee.dev/assets/og-card-brand.jpg',
    metadata: [
      {
        name: 'description',
        content: 'Help articles for Zee on Mac, iPad, and iPhone.',
      },
    ],
    colorMode: {
      defaultMode: 'light',
      disableSwitch: true,
      respectPrefersColorScheme: false,
    },
    navbar: {
      title: 'Zee Help',
      logo: {
        alt: 'Zee',
        src: 'img/zee-logo.svg',
      },
      items: [
        {type: 'docSidebar', sidebarId: 'helpSidebar', position: 'left', label: 'Articles'},
        {to: '/keyboard-shortcuts/', label: 'Shortcuts', position: 'left'},
        {to: '/extension-api-compatibility/', label: 'Compatibility', position: 'left'},
        {href: 'https://github.com/rafaelo96/Zee/releases/latest', label: 'Download for Mac', position: 'right'},
        {href: 'https://zee.dev/support/', label: 'Support', position: 'right'},
        {href: 'https://zee.dev/', label: 'Product site', position: 'right'},
      ],
    },
    docs: {
      sidebar: {
        hideable: true,
        autoCollapseCategories: false,
      },
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Zee',
          items: [
            {label: 'Product site', href: 'https://zee.dev/'},
            {label: 'Download for Mac', href: 'https://github.com/rafaelo96/Zee/releases/latest'},
          ],
        },
        {
          title: 'Help',
          items: [
            {label: 'All articles', to: '/'},
            {label: 'Keyboard shortcuts', to: '/keyboard-shortcuts/'},
            {label: 'Split View', to: '/split-view/'},
            {label: 'Extension compatibility', to: '/extension-api-compatibility/'},
            {label: 'Support', href: 'https://zee.dev/support/'},
          ],
        },
        {
          title: 'Community',
          items: [
            {label: 'GitHub Issues', href: 'https://github.com/rafaelo96/Zee/issues/new/choose'},
            {label: 'Privacy', href: 'https://zee.dev/privacy/'},
          ],
        },
      ],
      copyright: `Zee is not affiliated with Arc. © ${new Date().getFullYear()} Zee contributors.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  },
};

module.exports = config;
