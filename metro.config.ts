/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 */

const { mergeConfig } = require('@react-native/metro-config');

const config = mergeConfig(getDefaultConfig(__dirname), {
  // Add transformer to handle TypeScript files correctly
  transformer: {
    getTransformOptions: async () => ({
      inlineRequires: true,
      supportCache: false,
    }),
  },
  // Fix module resolution for TypeScript files
  resolver: {
    resolverMainFields: ['react-native', 'browser'],
  },
});

module.exports = config;
