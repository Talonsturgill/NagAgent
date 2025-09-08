import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Alert,
  SafeAreaView,
  StatusBar,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform
} from 'react-native';
import axios from 'axios';

const API_URL = 'https://web-production-6503.up.railway.app/api/v1';

// Personality options
const PERSONALITIES = [
  { id: 'brutal', name: 'Brutal Brandon', emoji: '😈', description: 'No mercy, pure motivation' },
  { id: 'sassy', name: 'Sassy Sarah', emoji: '💅', description: 'Sarcastic but effective' },
  { id: 'military', name: 'Military Mike', emoji: '🪖', description: 'Drill sergeant energy' },
  { id: 'spiritual', name: 'Spiritual Sage', emoji: '🧘', description: 'Mindful accountability' }
];

// Personality Selection Screen - Moved outside App to prevent re-creation
const PersonalityScreen = ({ 
  email, 
  setEmail, 
  password, 
  setPassword, 
  selectedPersonality, 
  setSelectedPersonality, 
  handleAuth, 
  loading 
}) => (
  <KeyboardAvoidingView 
    style={styles.container}
    behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
  >
    <Text style={styles.title}>Choose Your Coach</Text>
    <Text style={styles.subtitle}>Pick your accountability style</Text>
    
    <ScrollView style={styles.personalityList} keyboardShouldPersistTaps='always'>
      {PERSONALITIES.map((personality) => (
        <TouchableOpacity
          key={personality.id}
          style={[
            styles.personalityCard,
            selectedPersonality === personality.id && styles.selectedCard
          ]}
          onPress={() => setSelectedPersonality(personality.id)}
        >
          <Text style={styles.personalityEmoji}>{personality.emoji}</Text>
          <View style={styles.personalityInfo}>
            <Text style={styles.personalityName}>{personality.name}</Text>
            <Text style={styles.personalityDesc}>{personality.description}</Text>
          </View>
        </TouchableOpacity>
      ))}
    </ScrollView>

    <View style={styles.authSection}>
      <TextInput
        style={styles.input}
        placeholder="Email"
        value={email}
        onChangeText={setEmail}
        keyboardType="email-address"
        autoCapitalize="none"
      />
      <TextInput
        style={styles.input}
        placeholder="Password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
      />
    </View>

    <TouchableOpacity
      style={[styles.primaryButton, !selectedPersonality && styles.disabledButton]}
      onPress={handleAuth}
      disabled={!selectedPersonality || loading}
    >
      {loading ? (
        <ActivityIndicator color="white" />
      ) : (
        <Text style={styles.buttonText}>Continue</Text>
      )}
    </TouchableOpacity>
  </KeyboardAvoidingView>
);

export default function App() {
  const [currentScreen, setCurrentScreen] = useState('welcome');
  const [selectedPersonality, setSelectedPersonality] = useState(null);
  const [dailyGoals, setDailyGoals] = useState([]);
  const [newGoal, setNewGoal] = useState('');
  const [userToken, setUserToken] = useState(null);
  const [loading, setLoading] = useState(false);
  const [roastMessage, setRoastMessage] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  // Register/Login user
  const handleAuth = async () => {
    if (!email || !password) {
      Alert.alert('Error', 'Please enter email and password');
      return;
    }

    setLoading(true);
    try {
      // Try to register first
      const registerResponse = await axios.post(`${API_URL}/auth/register`, {
        email,
        password,
        personality_type: selectedPersonality
      });
      
      if (registerResponse.data.access_token) {
        setUserToken(registerResponse.data.access_token);
        setCurrentScreen('goals');
      }
    } catch (error) {
      // If registration fails, try login
      try {
        const formData = new URLSearchParams();
        formData.append('username', email);
        formData.append('password', password);
        const loginResponse = await axios.post(`${API_URL}/auth/login`, formData, {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
          }
        });
        
        if (loginResponse.data.access_token) {
          setUserToken(loginResponse.data.access_token);
          setCurrentScreen('goals');
        }
      } catch (loginError) {
        Alert.alert('Error', 'Failed to authenticate. Please try again.');
      }
    }
    setLoading(false);
  };

  // Get roast from backend
  const getRoast = async () => {
    if (!selectedPersonality) return;
    
    setLoading(true);
    try {
      const response = await axios.post(
        `${API_URL}/roasts/generate`,
        {
          personality: selectedPersonality,
          context: 'check_in',
          task_count: dailyGoals.length
        },
        {
          headers: userToken ? { Authorization: `Bearer ${userToken}` } : {}
        }
      );
      
      setRoastMessage(response.data.roast || getDefaultRoast());
    } catch (error) {
      // Use default roast if API fails
      setRoastMessage(getDefaultRoast());
    }
    setLoading(false);
  };

  // Default roast messages
  const getDefaultRoast = () => {
    const roasts = {
      brutal: "What are you waiting for? Your goals won't achieve themselves while you're sitting there!",
      sassy: "Oh honey, those goals aren't going to check themselves off. Get moving!",
      military: "DROP AND GIVE ME TWENTY! Then get those goals DONE, soldier!",
      spiritual: "Your potential is infinite, but action must meet intention. Begin now."
    };
    return roasts[selectedPersonality] || "Time to get to work!";
  };

  // Add a new goal
  const addGoal = () => {
    if (newGoal.trim()) {
      setDailyGoals([...dailyGoals, { id: Date.now(), text: newGoal, completed: false }]);
      setNewGoal('');
    }
  };

  // Toggle goal completion
  const toggleGoal = (id) => {
    setDailyGoals(dailyGoals.map(goal => 
      goal.id === id ? { ...goal, completed: !goal.completed } : goal
    ));
  };

  // Welcome Screen
  const WelcomeScreen = () => (
    <View style={styles.container}>
      <Text style={styles.title}>NagAgent</Text>
      <Text style={styles.subtitle}>Your AI Accountability Coach</Text>
      <Text style={styles.description}>
        Stop procrastinating. Start achieving.{'\n'}
        Get roasted into productivity.
      </Text>
      <TouchableOpacity style={styles.primaryButton} onPress={() => setCurrentScreen('personality')}>
        <Text style={styles.buttonText}>Get Started</Text>
      </TouchableOpacity>
    </View>
  );


  // Goals Screen
  const GoalsScreen = () => (
    <KeyboardAvoidingView 
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <Text style={styles.title}>Set Your Daily Goals</Text>
      <Text style={styles.subtitle}>What will you achieve today?</Text>

      <View style={styles.goalInputContainer}>
        <TextInput
          style={styles.goalInput}
          placeholder="Enter a goal..."
          value={newGoal}
          onChangeText={setNewGoal}
          onSubmitEditing={addGoal}
        />
        <TouchableOpacity style={styles.addButton} onPress={addGoal}>
          <Text style={styles.addButtonText}>+</Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.goalsList}>
        {dailyGoals.map((goal) => (
          <TouchableOpacity
            key={goal.id}
            style={styles.goalItem}
            onPress={() => toggleGoal(goal.id)}
          >
            <View style={[styles.checkbox, goal.completed && styles.checkedBox]}>
              {goal.completed && <Text style={styles.checkmark}>✓</Text>}
            </View>
            <Text style={[styles.goalText, goal.completed && styles.completedGoal]}>
              {goal.text}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      <TouchableOpacity
        style={[styles.primaryButton, dailyGoals.length === 0 && styles.disabledButton]}
        onPress={() => {
          getRoast();
          setCurrentScreen('dashboard');
        }}
        disabled={dailyGoals.length === 0}
      >
        <Text style={styles.buttonText}>Start My Day</Text>
      </TouchableOpacity>
    </KeyboardAvoidingView>
  );

  // Dashboard Screen
  const DashboardScreen = () => {
    useEffect(() => {
      if (!roastMessage) {
        getRoast();
      }
    }, []);

    const completedCount = dailyGoals.filter(g => g.completed).length;
    const totalCount = dailyGoals.length;
    const progress = totalCount > 0 ? (completedCount / totalCount) * 100 : 0;

    return (
      <ScrollView style={styles.container}>
        <Text style={styles.title}>Your Dashboard</Text>
        
        {/* Roast Section */}
        <View style={styles.roastCard}>
          <Text style={styles.roastTitle}>
            {PERSONALITIES.find(p => p.id === selectedPersonality)?.emoji} Message from your coach:
          </Text>
          <Text style={styles.roastMessage}>{roastMessage || "Loading..."}</Text>
          <TouchableOpacity style={styles.smallButton} onPress={getRoast}>
            <Text style={styles.smallButtonText}>Get New Roast</Text>
          </TouchableOpacity>
        </View>

        {/* Progress Section */}
        <View style={styles.progressCard}>
          <Text style={styles.progressTitle}>Today's Progress</Text>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: `${progress}%` }]} />
          </View>
          <Text style={styles.progressText}>
            {completedCount} of {totalCount} goals completed ({Math.round(progress)}%)
          </Text>
        </View>

        {/* Goals List */}
        <View style={styles.goalsCard}>
          <Text style={styles.sectionTitle}>Today's Goals</Text>
          {dailyGoals.map((goal) => (
            <TouchableOpacity
              key={goal.id}
              style={styles.dashboardGoalItem}
              onPress={() => toggleGoal(goal.id)}
            >
              <View style={[styles.checkbox, goal.completed && styles.checkedBox]}>
                {goal.completed && <Text style={styles.checkmark}>✓</Text>}
              </View>
              <Text style={[styles.goalText, goal.completed && styles.completedGoal]}>
                {goal.text}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <TouchableOpacity 
          style={styles.secondaryButton} 
          onPress={() => setCurrentScreen('goals')}
        >
          <Text style={styles.secondaryButtonText}>Edit Goals</Text>
        </TouchableOpacity>
      </ScrollView>
    );
  };

  // Render current screen
  const renderScreen = () => {
    switch (currentScreen) {
      case 'welcome':
        return <WelcomeScreen />;
      case 'personality':
        return <PersonalityScreen 
          email={email}
          setEmail={setEmail}
          password={password}
          setPassword={setPassword}
          selectedPersonality={selectedPersonality}
          setSelectedPersonality={setSelectedPersonality}
          handleAuth={handleAuth}
          loading={loading}
        />;
      case 'goals':
        return <GoalsScreen />;
      case 'dashboard':
        return <DashboardScreen />;
      default:
        return <WelcomeScreen />;
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" />
      {renderScreen()}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#333',
    textAlign: 'center',
    marginTop: 40,
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 18,
    color: '#666',
    textAlign: 'center',
    marginBottom: 20,
  },
  description: {
    fontSize: 16,
    color: '#777',
    textAlign: 'center',
    marginVertical: 30,
    lineHeight: 24,
  },
  primaryButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 15,
    paddingHorizontal: 30,
    borderRadius: 10,
    marginTop: 20,
  },
  buttonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: '600',
    textAlign: 'center',
  },
  disabledButton: {
    backgroundColor: '#ccc',
  },
  personalityList: {
    flex: 1,
    marginVertical: 20,
  },
  personalityCard: {
    flexDirection: 'row',
    backgroundColor: 'white',
    padding: 20,
    borderRadius: 15,
    marginBottom: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  selectedCard: {
    borderColor: '#007AFF',
    borderWidth: 2,
  },
  personalityEmoji: {
    fontSize: 40,
    marginRight: 15,
  },
  personalityInfo: {
    flex: 1,
  },
  personalityName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 5,
  },
  personalityDesc: {
    fontSize: 14,
    color: '#666',
  },
  authSection: {
    marginVertical: 20,
  },
  input: {
    backgroundColor: 'white',
    paddingHorizontal: 15,
    paddingVertical: 12,
    borderRadius: 10,
    fontSize: 16,
    marginBottom: 15,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  goalInputContainer: {
    flexDirection: 'row',
    marginVertical: 20,
  },
  goalInput: {
    flex: 1,
    backgroundColor: 'white',
    paddingHorizontal: 15,
    paddingVertical: 12,
    borderRadius: 10,
    fontSize: 16,
    borderWidth: 1,
    borderColor: '#ddd',
    marginRight: 10,
  },
  addButton: {
    backgroundColor: '#007AFF',
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: 'center',
    alignItems: 'center',
  },
  addButtonText: {
    color: 'white',
    fontSize: 24,
    fontWeight: '600',
  },
  goalsList: {
    flex: 1,
    marginBottom: 20,
  },
  goalItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'white',
    padding: 15,
    borderRadius: 10,
    marginBottom: 10,
  },
  dashboardGoalItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
  },
  checkbox: {
    width: 24,
    height: 24,
    borderWidth: 2,
    borderColor: '#007AFF',
    borderRadius: 5,
    marginRight: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  checkedBox: {
    backgroundColor: '#007AFF',
  },
  checkmark: {
    color: 'white',
    fontWeight: 'bold',
  },
  goalText: {
    fontSize: 16,
    color: '#333',
    flex: 1,
  },
  completedGoal: {
    textDecorationLine: 'line-through',
    color: '#999',
  },
  roastCard: {
    backgroundColor: '#FFE5E5',
    padding: 20,
    borderRadius: 15,
    marginVertical: 20,
  },
  roastTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 10,
  },
  roastMessage: {
    fontSize: 18,
    color: '#d32f2f',
    fontWeight: '500',
    lineHeight: 26,
    marginBottom: 15,
  },
  smallButton: {
    backgroundColor: '#d32f2f',
    paddingVertical: 8,
    paddingHorizontal: 15,
    borderRadius: 8,
    alignSelf: 'flex-start',
  },
  smallButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
  progressCard: {
    backgroundColor: 'white',
    padding: 20,
    borderRadius: 15,
    marginBottom: 20,
  },
  progressTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 15,
  },
  progressBar: {
    height: 20,
    backgroundColor: '#E0E0E0',
    borderRadius: 10,
    marginBottom: 10,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#4CAF50',
  },
  progressText: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
  },
  goalsCard: {
    backgroundColor: 'white',
    padding: 20,
    borderRadius: 15,
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 15,
  },
  secondaryButton: {
    borderWidth: 2,
    borderColor: '#007AFF',
    paddingVertical: 12,
    paddingHorizontal: 25,
    borderRadius: 10,
    marginBottom: 30,
  },
  secondaryButtonText: {
    color: '#007AFF',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
});