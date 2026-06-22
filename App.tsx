import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  TextInput,
  StatusBar,
  SafeAreaView,
  ActivityIndicator,
  Linking,
  Alert,
} from 'react-native';
import {
  ViroARSceneNavigator,
  ViroARScene,
  ViroARImageMarker,
  ViroVideo,
  ViroARTrackingTargets,
  ViroAmbientLight,
} from '@reactvision/react-viro';

// Interface for dynamic client AR configuration
interface ClientARConfig {
  id: string;
  name: string;
  targetImageUrl: string;
  videoUrl: string;
  physicalWidth: number; // in meters, e.g. 0.15 for a postcard
}

// Preset configurations for instant local testing and fallback
const PRESET_CLIENTS: Record<string, ClientARConfig> = {
  postcard: {
    id: 'postcard',
    name: 'India Postcard Experience',
    targetImageUrl: 'https://raw.githubusercontent.com/prashant1998gupta/AR_ImageTracking/main/Assets/AR_Assets/India%20Post%20card/Postcard_Target_Image.jpg.jpeg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    physicalWidth: 0.15,
  },
  wedding: {
    id: 'wedding',
    name: 'Royal Wedding Invite',
    targetImageUrl: 'https://raw.githubusercontent.com/prashant1998gupta/AR_ImageTracking/main/Assets/AR_Assets/India%20Post%20card/Postcard_Target_Image.jpg.jpeg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    physicalWidth: 0.12,
  },
};

// AR Scene Component - Runs inside ViroARSceneNavigator
// It receives the active config via sceneNavigator's shared props
const DynamicARScene = (props: any) => {
  const config: ClientARConfig | null = props.sceneNavigator.viroAppProps?.config;

  if (!config) {
    return null;
  }

  return (
    <ViroARScene>
      <ViroAmbientLight color="#ffffff" />
      {/* ViroARImageMarker tracks the registered "dynamicTarget" */}
      <ViroARImageMarker target="dynamicTarget">
        <ViroVideo
          source={{ uri: config.videoUrl }}
          loop={true}
          position={[0, 0, 0]}
          scale={[1, 1, 1]}
          rotation={[-90, 0, 0]} // Lay flat on top of the image marker
          dragType="FixedToPlane"
          onDrag={() => {}}
        />
      </ViroARImageMarker>
    </ViroARScene>
  );
};

export default function App() {
  const [appState, setAppState] = useState<'IDLE' | 'LOADING' | 'AR_PLAYING'>('IDLE');
  const [activeConfig, setActiveConfig] = useState<ClientARConfig | null>(null);
  const [customClientId, setCustomClientId] = useState('');
  const [statusMessage, setStatusMessage] = useState('');

  // 1. Deep linking listener
  useEffect(() => {
    // Process deep link URL
    const handleDeepLink = async (url: string | null) => {
      if (!url) return;
      
      console.log('Received deep link URL:', url);
      try {
        // Example URL: masterar://experience?client=postcard
        // Example URL: https://ar.yourdomain.com/experience?client=wedding
        const parsedUrl = new URL(url);
        const client = parsedUrl.searchParams.get('client');
        if (client) {
          loadClientExperience(client);
        } else {
          Alert.alert('Invalid Link', 'No client parameter found in the link.');
        }
      } catch (error) {
        // Fallback simple parsing for non-standard URI schemes
        const clientParam = url.split('client=')[1];
        if (clientParam) {
          const client = clientParam.split('&')[0];
          loadClientExperience(client);
        } else {
          Alert.alert('Parsing Error', 'Failed to parse deep link: ' + url);
        }
      }
    };

    // Check if app was opened via a link
    Linking.getInitialURL().then(handleDeepLink);

    // Listen for new links while app is open
    const subscription = Linking.addEventListener('url', (event) => {
      handleDeepLink(event.url);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  // 2. Fetch and register client configuration
  const loadClientExperience = async (clientId: string) => {
    setAppState('LOADING');
    setStatusMessage('Fetching experience settings...');

    try {
      let config: ClientARConfig;

      // Check if it's one of our built-in test presets
      if (PRESET_CLIENTS[clientId]) {
        config = PRESET_CLIENTS[clientId];
      } else {
        // Fetch config from your remote SaaS API server
        // Example structure of remote endpoint: https://api.yourdomain.com/clients/{clientId}
        setStatusMessage(`Downloading config for client: ${clientId}...`);
        const response = await fetch(`https://api.yourdomain.com/clients/${clientId}`);
        if (!response.ok) {
          throw new Error(`Client configuration not found on server (HTTP ${response.status})`);
        }
        config = await response.json();
      }

      setStatusMessage('Registering AR tracking targets...');
      
      // Dynamic target registration
      // ViroARTrackingTargets downloads the target image directly from the URL
      ViroARTrackingTargets.createTargets({
        dynamicTarget: {
          source: { uri: config.targetImageUrl },
          orientation: 'Up',
          physicalWidth: config.physicalWidth,
        },
      });

      setActiveConfig(config);
      
      // Give a tiny buffer for target creation
      setTimeout(() => {
        setAppState('AR_PLAYING');
      }, 1000);

    } catch (error: any) {
      console.error(error);
      Alert.alert('Configuration Error', error.message || 'Failed to load AR experience.');
      setAppState('IDLE');
    }
  };

  const handleCustomLaunch = () => {
    if (!customClientId.trim()) {
      Alert.alert('Error', 'Please enter a Client ID');
      return;
    }
    loadClientExperience(customClientId.trim().toLowerCase());
  };

  return (
    <SafeAreaView style={styles.root}>
      <StatusBar barStyle="light-content" backgroundColor="#0f172a" />

      {appState === 'IDLE' && (
        <View style={styles.container}>
          <Text style={styles.title}>Dynamic AR Player</Text>
          <Text style={styles.subtitle}>
            Enter a client code or tap a test preset to load the dynamic tracking target and overlay video.
          </Text>

          {/* Preset Buttons */}
          <View style={styles.presetsCard}>
            <Text style={styles.cardHeader}>Test Presets</Text>
            {Object.keys(PRESET_CLIENTS).map((key) => (
              <TouchableOpacity
                key={key}
                style={styles.presetButton}
                onPress={() => loadClientExperience(key)}
              >
                <Text style={styles.presetButtonText}>{PRESET_CLIENTS[key].name}</Text>
                <Text style={styles.presetButtonSubtext}>ID: {key}</Text>
              </TouchableOpacity>
            ))}
          </View>

          {/* Custom ID Input */}
          <View style={styles.inputCard}>
            <Text style={styles.cardHeader}>SaaS Client ID</Text>
            <TextInput
              style={styles.input}
              placeholder="e.g., custom_client_123"
              placeholderTextColor="#64748b"
              value={customClientId}
              onChangeText={setCustomClientId}
              autoCapitalize="none"
              autoCorrect={false}
            />
            <TouchableOpacity style={styles.launchButton} onPress={handleCustomLaunch}>
              <Text style={styles.launchButtonText}>Load Client Experience</Text>
            </TouchableOpacity>
          </View>

          {/* Deep link info */}
          <View style={styles.infoCard}>
            <Text style={styles.infoTitle}>Deep Link Testing URL format:</Text>
            <Text style={styles.infoCode}>masterar://experience?client=postcard</Text>
          </View>
        </View>
      )}

      {appState === 'LOADING' && (
        <View style={[styles.container, styles.center]}>
          <ActivityIndicator size="large" color="#6366f1" />
          <Text style={styles.loadingText}>{statusMessage}</Text>
        </View>
      )}

      {appState === 'AR_PLAYING' && (
        <View style={styles.arContainer}>
          {/* ViroARSceneNavigator loads the DynamicARScene */}
          <ViroARSceneNavigator
            initialScene={{ scene: DynamicARScene }}
            viroAppProps={{ config: activeConfig }}
            style={StyleSheet.absoluteFillObject}
          />

          {/* Top Instructions HUD */}
          <View style={styles.hudOverlay}>
            <Text style={styles.hudClientName}>{activeConfig?.name}</Text>
            <Text style={styles.hudInstructions}>
              Point camera at the target image to play video
            </Text>
          </View>

          {/* Back Floating Button */}
          <TouchableOpacity
            style={styles.backButton}
            onPress={() => {
              setAppState('IDLE');
              setActiveConfig(null);
            }}
          >
            <Text style={styles.backButtonText}>← Close</Text>
          </TouchableOpacity>
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#0f172a', // Premium dark slate background
  },
  container: {
    flex: 1,
    padding: 24,
    justifyContent: 'center',
  },
  center: {
    alignItems: 'center',
  },
  arContainer: {
    flex: 1,
  },
  title: {
    fontSize: 28,
    fontWeight: '800',
    color: '#f8fafc',
    textAlign: 'center',
    marginBottom: 8,
    letterSpacing: 0.5,
  },
  subtitle: {
    fontSize: 14,
    color: '#94a3b8',
    textAlign: 'center',
    marginBottom: 32,
    lineHeight: 20,
  },
  presetsCard: {
    backgroundColor: '#1e293b',
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#334155',
  },
  inputCard: {
    backgroundColor: '#1e293b',
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#334155',
  },
  cardHeader: {
    fontSize: 16,
    fontWeight: '700',
    color: '#e2e8f0',
    marginBottom: 12,
  },
  presetButton: {
    backgroundColor: '#334155',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 10,
    marginBottom: 10,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  presetButtonText: {
    color: '#f8fafc',
    fontWeight: '600',
  },
  presetButtonSubtext: {
    color: '#94a3b8',
    fontSize: 12,
  },
  input: {
    backgroundColor: '#0f172a',
    borderRadius: 10,
    color: '#f8fafc',
    paddingVertical: 12,
    paddingHorizontal: 16,
    fontSize: 15,
    borderWidth: 1,
    borderColor: '#475569',
    marginBottom: 12,
  },
  launchButton: {
    backgroundColor: '#6366f1', // Premium indigo accent
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: 'center',
  },
  launchButtonText: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '700',
  },
  infoCard: {
    backgroundColor: '#0f172a',
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#1e293b',
  },
  infoTitle: {
    color: '#94a3b8',
    fontSize: 12,
    marginBottom: 4,
  },
  infoCode: {
    color: '#38bdf8', // Light blue link color
    fontFamily: 'monospace',
    fontSize: 12,
  },
  loadingText: {
    color: '#f8fafc',
    marginTop: 16,
    fontSize: 15,
    fontWeight: '600',
  },
  hudOverlay: {
    position: 'absolute',
    top: 24,
    left: 20,
    right: 20,
    backgroundColor: 'rgba(15, 23, 42, 0.85)',
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  hudClientName: {
    color: '#f8fafc',
    fontSize: 16,
    fontWeight: '700',
    marginBottom: 4,
  },
  hudInstructions: {
    color: '#a5b4fc',
    fontSize: 12,
    textAlign: 'center',
  },
  backButton: {
    position: 'absolute',
    bottom: 30,
    alignSelf: 'center',
    backgroundColor: '#ef4444',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 30,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 5,
  },
  backButtonText: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '700',
  },
});
