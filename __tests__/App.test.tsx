/**
 * @format
 */

import React from 'react';
import ReactTestRenderer from 'react-test-renderer';
import App, {getCampaignIdFromUrl} from '../App';

jest.mock('@reactvision/react-viro', () => ({
  ViroAmbientLight: 'ViroAmbientLight',
  ViroARImageMarker: 'ViroARImageMarker',
  ViroARScene: 'ViroARScene',
  ViroARSceneNavigator: 'ViroARSceneNavigator',
  ViroARTrackingTargets: {createTargets: jest.fn()},
  ViroVideo: 'ViroVideo',
}));

test('renders correctly', async () => {
  await ReactTestRenderer.act(() => {
    ReactTestRenderer.create(<App />);
  });
});

test.each([
  ['masterar://experience?client=postcard', 'postcard'],
  ['https://ar.yourdomain.com/e/wedding', 'wedding'],
  ['https://ar.yourdomain.com/experience/demo?ignored=true', 'demo'],
  ['https://ar.yourdomain.com/e/path-id?campaign=query-id', 'query-id'],
])('extracts a campaign ID from %s', (url, expected) => {
  expect(getCampaignIdFromUrl(url)).toBe(expected);
});
