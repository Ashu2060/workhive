  import 'package:flutter/material.dart';
  import 'dart:async';
  import 'dart:math';
  import 'admin_map_view.dart';
  import 'package:flutter_map/flutter_map.dart';
  import 'package:latlong2/latlong.dart' as ll;



  // --- DATA MODELS ---
  
  // Represents a worker, their status, location data, and approval status
  class Worker {
    final String id;
    final String name;
    final String email;
    final String role; // Added role property
    double latitude;
    double longitude;
    String status; // 'Stopped', 'Tracking', 'Held'
    bool isInsideGeofence;
    bool isApproved; // NEW: Approval status for login
  
    Worker({
      required this.id,
      required this.name,
      required this.email,
      this.role = 'Field Worker', // Default role
      this.latitude = 28.6588928, // Simulated San Francisco Lat
      this.longitude = 77.4373376, // Simulated San Francisco Long
      this.status = 'Stopped',
      this.isInsideGeofence = false,
      this.isApproved = false, // Default to false for new registrations
    });
  }
  // --- GLOBAL STATE MANAGEMENT (Simulating Database and Backend) ---
  
  class WorkerManager extends ChangeNotifier {
    // Simulating initial workers (DB entries) - set them as approved
    final List<Worker> _workers = [
      Worker(id: 'w001', name: 'Alia Khan', email: 'alia@company.com', isApproved: true),
      Worker(id: 'w002', name: 'Rohan Sharma', email: 'rohan@company.com', isApproved: true),
      Worker(id: 'w003', name: 'Sara Jones', email: 'sara@company.com', isApproved: true),
    ];
  
    List<Worker> get workers => _workers;
    List<Worker> get pendingWorkers => _workers.where((w) => !w.isApproved).toList();
  
    // Simulated Geofence Center (e.g., Company HQ)
    static const double _geofenceLat = 28.6588928;
    static const double _geofenceLon = 77.4373376;
    static const double _geofenceRadiusKm = 0.5; // 500 meters
  
    // Finds a worker by ID
    Worker? findWorker(String id) {
      try {
        return _workers.firstWhere((w) => w.id == id);
      } catch (e) {
        return null;
      }
    }
  
    // --- EMPLOYEE ACTIONS ---
  
    // Updates the worker's status (Start, Hold, Stop)
    void updateWorkerStatus(String id, String newStatus) {
      final worker = findWorker(id);
      if (worker != null) {
        worker.status = newStatus;
        notifyListeners();
        // Start or stop the tracking timer based on status
        if (newStatus == 'Tracking') {
          _startTrackingTimer(worker);
        } else {
          _stopTrackingTimer(worker);
        }
      }
    }
  
    // Timer map to manage the 10-second updates for each worker
    final Map<String, Timer> _trackingTimers = {};
  
    void _startTrackingTimer(Worker worker) {
      _stopTrackingTimer(worker); // Ensure only one timer is active
  
      // Fulfills the requirement: Fetch location every 10 seconds
      final timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (worker.status == 'Tracking') {
          _simulateLocationUpdate(worker);
          notifyListeners();
        } else {
          // If status changed to Held or Stopped, stop this timer
          timer.cancel();
          _trackingTimers.remove(worker.id);
        }
      });
      _trackingTimers[worker.id] = timer;
    }
  
    void _stopTrackingTimer(Worker worker) {
      _trackingTimers[worker.id]?.cancel();
      _trackingTimers.remove(worker.id);
    }
  
    // Simulates location change and geofence check
    void _simulateLocationUpdate(Worker worker) {
      final random = Random();
  
      // Simulate slight movement (in the range of 0.0001 degrees, about 11 meters)
      worker.latitude += (random.nextDouble() - 0.5) * 0.0002;
      worker.longitude += (random.nextDouble() - 0.5) * 0.0002;
  
      // Calculate distance for Geofence check
      const double R = 6371; // Earth's radius in km
      final dLat = (_geofenceLat - worker.latitude) * pi / 180;
      final dLon = (_geofenceLon - worker.longitude) * pi / 180;
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(worker.latitude * pi / 180) * cos(_geofenceLat * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      final distanceKm = R * c;
  
      worker.isInsideGeofence = distanceKm <= _geofenceRadiusKm;
    }
  
    // Public method to manually stop all timers when app closes (good practice)
    void disposeTimers() {
      for (var timer in _trackingTimers.values) {
        timer.cancel();
      }
      _trackingTimers.clear();
    }
  
    // --- REGISTRATION AND ADMIN APPROVAL ---
  
    // Registers a new worker and sets their status to not approved
    bool registerWorker(String name, String email) {
      if (_workers.any((w) => w.email.toLowerCase() == email.toLowerCase())) {
        return false; // Email already exists
      }
  
      final newId = 'w${(_workers.length + 1).toString().padLeft(3, '0')}';
  
      final newWorker = Worker(
        id: newId,
        name: name,
        email: email,
        isApproved: false, // Must be approved by admin
      );
      _workers.add(newWorker);
      notifyListeners();
      return true;
    }
  
    // Admin approval/rejection logic
    void approveWorker(String id, bool approve) {
      final worker = findWorker(id);
      if (worker != null) {
        worker.isApproved = approve;
        // If approved, set initial status to 'Stopped'
        if (approve) {
          worker.status = 'Stopped';
        } else {
          // If rejected, remove them from the list (simulated rejection)
          _workers.removeWhere((w) => w.id == id);
        }
        notifyListeners();
      }
    }
  }
  
  // Global instance of the manager
  final workerManager = WorkerManager();
  
  
  // --- CONFIGURATION AND MAIN APPLICATION ---
  
  void main() {
    runApp(const WorkHiveApp());
  }
  
  class WorkHiveApp extends StatelessWidget {
    const WorkHiveApp({super.key});
  
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'WorkHive Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          fontFamily: 'Inter',
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: const Color(0xFF1E1F30), // Dark background for the whole app
        ),
        home: const LoginPage(),
        routes: {
          '/admin': (context) => const AdminHomePage(),
          '/register': (context) => RegistrationPage(),
        },
      );
    }
  }
  
  // --- SHARED WIDGETS ---
  
  /// A custom input field with a modern, lifted design (using shadow)
  class CustomInputField extends StatelessWidget {
    final String label;
    final IconData icon;
    final bool isPassword;
    final TextEditingController? controller;
  
    const CustomInputField({
      super.key,
      required this.label,
      required this.icon,
      this.isPassword = false,
      this.controller,
    });
  
    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25), // 10% opacity
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: Color(0xFF1E1F30)),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: const Color(0xFF1E1F30).withAlpha(178), // 70% opacity
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF6A0DAD)), // Deep Purple Icon
              border: InputBorder.none, // Remove default border
              contentPadding: const EdgeInsets.all(16.0),
            ),
          ),
        ),
      );
    }
  }
  
  /// A primary button with a gradient background
  class GradientButton extends StatelessWidget {
    final String text;
    final VoidCallback onPressed;
    final double width;
    final List<Color> colors;
    final bool isSmall;
  
    const GradientButton({
      super.key,
      required this.text,
      required this.onPressed,
      this.width = double.infinity,
      this.colors = const [Color(0xFF6A0DAD), Color(0xFFC70039)], // Deep Purple to Ruby Red
      this.isSmall = false,
    });
  
    @override
    Widget build(BuildContext context) {
      return Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: colors[0].withAlpha(127), // 50% opacity
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: isSmall
                  ? const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)
                  : const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
  
  // Helper to show messages
  void _showMessage(BuildContext context, String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // --- REGISTRATION PAGE (New Feature) ---
  
  class RegistrationPage extends StatelessWidget {
    RegistrationPage({super.key});
  
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController(); // Password is only simulated here
  
    void _register(BuildContext context) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
  
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        _showMessage(context, 'Please fill in all fields.');
        return;
      }
  
      if (!email.contains('@') || !email.contains('.')) {
        _showMessage(context, 'Please enter a valid email address.');
        return;
      }
  
      // Attempt to register the worker
      final success = workerManager.registerWorker(name, email);
  
      if (success) {
        _showMessage(context, 'Registration Successful! Waiting for Admin approval.', isSuccess: true);
        // Navigate back to login
        Navigator.of(context).pop();
      } else {
        _showMessage(context, 'Registration Failed. Email already exists.');
      }
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('New Employee Registration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF3B0068),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1F30), Color(0xFF3B0068)], // Dark Navy to Deep Violet
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Join WorkHive',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
  
                  // Input Fields
                  CustomInputField(label: 'Full Name', icon: Icons.person_outline, controller: _nameController),
                  CustomInputField(label: 'Email (e.g., new@company.com)', icon: Icons.email_outlined, controller: _emailController),
                  CustomInputField(label: 'Password (Simulated)', icon: Icons.lock_outline, isPassword: true, controller: _passwordController),
  
                  const SizedBox(height: 30),
  
                  // Register Button
                  GradientButton(text: 'REGISTER & REQUEST APPROVAL', onPressed: () => _register(context)),
  
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Login', style: TextStyle(color: Colors.white70)),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
  
  // --- LOGIN PAGE (Modified for Approval Check) ---
  
  class LoginPage extends StatefulWidget {
    const LoginPage({super.key});
  
    @override
    State<LoginPage> createState() => _LoginPageState();
  }
  
  class _LoginPageState extends State<LoginPage> {
    bool _isAdmin = false;
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _privateKeyController = TextEditingController();
  
    // Use a simulated worker ID for the employee login to grab their data from the manager
    String _employeeId = '';
  
    void _login() {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final key = _privateKeyController.text.trim();
  
      // Simulated Validation
      if (email.isEmpty || password.isEmpty) {
        _showMessage(context, 'Please fill in Email and Password.');
        return;
      }
  
      if (_isAdmin) {
        // --- ADMIN LOGIN LOGIC ---
        const String adminName = 'Ashutosh';
        const String adminEmail = 'ashu@gmail.com';
        const String adminPassword = '805030';
        const String adminKey = 'aurasecret';
  
        if (name != adminName || email != adminEmail || password != adminPassword || key != adminKey) {
          _showMessage(context, 'Admin login failed: Invalid Name, Email, Password, or Private Key.');
          return;
        }
  
        _showMessage(context, 'Admin Login Successful! Redirecting...', isSuccess: true);
        // Navigate to Admin Page
        Navigator.of(context).pushReplacementNamed('/admin');
      } else {
        // Find the worker ID based on email (simulated)
        final worker = workerManager.workers.firstWhere(
              (w) => w.email.toLowerCase() == email.toLowerCase(),
          orElse: () => Worker(id: '', name: '', email: '', isApproved: false),
        );
  
        if (worker.id.isNotEmpty) {
          if (!worker.isApproved) {
            _showMessage(context, 'Login Failed: Your account is pending Admin approval.');
            return;
          }
  
          _employeeId = worker.id;
          _showMessage(context, 'Employee Login Successful! Redirecting...', isSuccess: true);
          // Navigate to Employee Page, passing the worker ID
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => EmployeeHomePage(workerId: _employeeId),
            ),
          );
        } else {
          _showMessage(context, 'Employee Login Failed: Invalid credentials or account not registered.');
        }
      }
    }
  
    @override
    Widget build(BuildContext context) {
      String nameLabel = _isAdmin ? 'Admin Name: Ashutosh' : 'Full Name (Simulated)';
      String emailLabel = _isAdmin ? 'Admin Email: ashu@gmail.com' : 'Email (e.g., alia@company.com)';
      String passwordLabel = _isAdmin ? 'Admin Password: 805030' : 'Password';
  
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1F30), Color(0xFF3B0068)], // Dark Navy to Deep Violet
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Logo Section (WorkHive Access)
                  const Icon(Icons.location_on, size: 80, color: Color(0xFFC70039)),
                  const SizedBox(height: 10),
                  const Text(
                    'WorkHive Tracker',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
  
                  // Admin/Employee Toggle
                  Row(
                    children: [
                      const Text('Login as Admin (Owner)', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: _isAdmin,
                        onChanged: (value) { setState(() { _isAdmin = value; }); },
                        activeThumbColor: const Color(0xFFC70039),
                        activeTrackColor: const Color(0xFFC70039).withAlpha(127), // 50% opacity for track
                        inactiveTrackColor: Colors.white30,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
  
                  // Input Fields
                  CustomInputField(label: nameLabel, icon: Icons.person_outline, controller: _nameController),
                  CustomInputField(label: emailLabel, icon: Icons.email_outlined, controller: _emailController),
                  CustomInputField(label: passwordLabel, icon: Icons.lock_outline, isPassword: true, controller: _passwordController),
  
                  // Admin Private Key (Conditional)
                  if (_isAdmin) ...[
                    CustomInputField(
                      label: 'Admin Private Key: aurasecret',
                      icon: Icons.security,
                      isPassword: true,
                      controller: _privateKeyController,
                    ),
                    const SizedBox(height: 20),
                  ],
  
                  const SizedBox(height: 30),
  
                  // Login Button
                  GradientButton(text: 'SECURE LOGIN', onPressed: _login),
                  const SizedBox(height: 20),
  
                  // Registration Link
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register');
                    },
                    child: const Text(
                      'New Employee? Register Here!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
  
  // --- EMPLOYEE HOME PAGE (Worker Dashboard) ---
  
  class EmployeeHomePage extends StatelessWidget {
    final String workerId;
  
    const EmployeeHomePage({super.key, required this.workerId});
  
    // Action button builder
    Widget _buildActionButton({
      required String text,
      required Color color,
      required VoidCallback onPressed,
      required IconData icon,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)],
                ),
                child: IconButton(
                  icon: Icon(icon, color: Colors.white, size: 36),
                  onPressed: onPressed,
                  padding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 8),
              Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
  
    // Custom Card for Status
    Widget _buildStatusCard(String title, String value, Color color) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2D43), // Slightly lighter dark background
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  
    @override
    Widget build(BuildContext context) {
      return ListenableBuilder(
        listenable: workerManager,
        builder: (context, child) {
          final worker = workerManager.findWorker(workerId);
          if (worker == null || !worker.isApproved) {
            // Safety check in case admin revokes approval while logged in
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                      'Access Denied or Data Not Found. Please contact Admin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent, fontSize: 18)
                  ),
                ),
              ),
            );
          }
  
          final isTracking = worker.status == 'Tracking';
          final isHeld = worker.status == 'Held';
  
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF3B0068),
              title: const Text('Worker Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  onPressed: () {
                    // Stop tracking before logging out
                    workerManager.updateWorkerStatus(workerId, 'Stopped');
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- PROFILE SECTION ---
                    _buildStatusCard(
                      'Welcome, ${worker.name}',
                      'Status: ${worker.status}',
                      isTracking ? Colors.greenAccent : (isHeld ? Colors.orangeAccent : Colors.redAccent),
                    ),
                    const SizedBox(height: 20),
  
                    // --- LOCATION CONTROLS ---
                    const Text('Location Tracking Controls', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // START Button
                        _buildActionButton(
                          text: 'START',
                          icon: Icons.play_arrow,
                          color: Colors.green.shade700,
                          onPressed: isTracking ? () {} : () => workerManager.updateWorkerStatus(workerId, 'Tracking'),
                        ),
                        // HOLD Button
                        _buildActionButton(
                          text: 'HOLD',
                          icon: Icons.pause,
                          color: Colors.orange.shade700,
                          onPressed: isHeld || !isTracking ? () {} : () => workerManager.updateWorkerStatus(workerId, 'Held'),
                        ),
                        // STOP Button
                        _buildActionButton(
                          text: 'STOP',
                          icon: Icons.stop,
                          color: Colors.red.shade700,
                          onPressed: !isTracking && !isHeld ? () {} : () => workerManager.updateWorkerStatus(workerId, 'Stopped'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
  
                    // --- LOCATION DATA (Simulated Real-time) ---
                    const Text('Live Tracking Data (10s Update)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white30),
  
                    // Geofence Status
                    _buildStatusCard(
                      'Geofence Status',
                      worker.isInsideGeofence ? 'INSIDE COMPANY RANGE' : 'OUTSIDE COMPANY RANGE',
                      worker.isInsideGeofence ? Colors.blueAccent : Colors.amber,
                    ),
                    const SizedBox(height: 15),
  
                    // Coordinates
                    _buildStatusCard(
                      'Current Location (Lat/Long)',
                      'Lat: ${worker.latitude.toStringAsFixed(6)}\nLong: ${worker.longitude.toStringAsFixed(6)}',
                      Colors.pinkAccent,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }
  
  
  // --- ADMIN HOME PAGE (Owner Dashboard - Modified to show Pending Workers) ---
  
  class AdminHomePage extends StatelessWidget {
    const AdminHomePage({super.key});
  
    // Custom Card for Worker List Item
    Widget _buildWorkerCard(Worker worker, BuildContext context, {bool isPending = false}) {
      Color statusColor;
      if (isPending) {
        statusColor = Colors.yellow;
      } else {
        switch (worker.status) {
          case 'Tracking': statusColor = Colors.greenAccent; break;
          case 'Held': statusColor = Colors.orangeAccent; break;
          default: statusColor = Colors.redAccent; break;
        }
      }
  
      return Card(
        color: const Color(0xFF2C2D43),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(
              isPending ? Icons.pending_actions : Icons.person_pin_circle,
              color: statusColor,
              size: 40
          ),
          title: Text(
              '${worker.name} ${isPending ? '(PENDING)' : ''}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                isPending
                    ? 'Email: ${worker.email}'
                    : 'Status: ${worker.status} | Geo: ${worker.isInsideGeofence ? 'IN' : 'OUT'}',
                style: TextStyle(color: statusColor.withAlpha(204), fontSize: 14), // 80% opacity
              ),
              if (!isPending)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Lat: ${worker.latitude.toStringAsFixed(4)}, Long: ${worker.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),
          trailing: isPending
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                onPressed: () {
                  workerManager.approveWorker(worker.id, true);
                  _showMessage(context, '${worker.name} approved successfully!', isSuccess: true);
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.redAccent),
                onPressed: () {
                  workerManager.approveWorker(worker.id, false);
                  _showMessage(context, '${worker.name} rejected and removed.', isSuccess: false);
                },
              ),
            ],
          )
              : const Icon(Icons.arrow_forward_ios, color: Colors.white30),
          onTap: isPending
              ? null
              : () {
            // Navigate to a detail view for a specific worker
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => WorkerDetailView(workerId: worker.id),
            ));
          },
        ),
      );
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF3B0068),
          title: const Text('WorkHive Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.map, color: Colors.white),
              tooltip: 'View All Workers on Map',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const AdminMapView(),
                ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: workerManager,
          builder: (context, child) {
            final approvedWorkers = workerManager.workers.where((w) => w.isApproved).toList();
            final pendingWorkers = workerManager.pendingWorkers;
  
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PENDING WORKERS SECTION ---
                  if (pendingWorkers.isNotEmpty) ...[
                    Text(
                        'Pending Approvals (${pendingWorkers.length})',
                        style: const TextStyle(color: Colors.yellowAccent, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    const Divider(color: Colors.white30),
                    ...pendingWorkers.map((worker) => _buildWorkerCard(worker, context, isPending: true)).toList(),
                    const SizedBox(height: 20),
                  ],
  
                  // --- LIVE WORKERS SECTION ---
                  Text(
                      'Live Worker Location Feed (${approvedWorkers.length} Active)',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  const Divider(color: Colors.white30),
                  Expanded(
                    child: ListView.builder(
                      itemCount: approvedWorkers.length,
                      itemBuilder: (context, index) {
                        return _buildWorkerCard(approvedWorkers[index], context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showMessage(context, 'Add Worker feature coming soon!');
          },
          backgroundColor: const Color(0xFF6A0DAD),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }
  }
  
  // --- WORKER DETAIL PAGE WITH GOOGLE MAPS (Admin View) ---

  class WorkerDetailView extends StatefulWidget {
    final String workerId;

    const WorkerDetailView({super.key, required this.workerId});

    @override
    State<WorkerDetailView> createState() => _WorkerDetailViewState();
  }

  class _WorkerDetailViewState extends State<WorkerDetailView> {

    Timer? _mapUpdateTimer;

    @override
    void initState() {
      super.initState();
      // Update map markers every 3 seconds for real-time tracking
      _mapUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {}); // Refresh to update marker positions
        }
      });
    }

    @override
    void dispose() {
      _mapUpdateTimer?.cancel();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF3B0068),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Worker Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: ListenableBuilder(
          listenable: workerManager,
          builder: (context, child) {
            final worker = workerManager.findWorker(widget.workerId);
            if (worker == null || !worker.isApproved) {
              return const Center(child: Text('Error loading data or Worker not approved.', style: TextStyle(color: Colors.white)));
            }

            Color statusColor;
            switch (worker.status) {
              case 'Tracking': statusColor = Colors.greenAccent; break;
              case 'Held': statusColor = Colors.orangeAccent; break;
              default: statusColor = Colors.redAccent; break;
            }

            // Worker position
            final workerPosition = ll.LatLng(worker.latitude, worker.longitude);
            // Geofence center
            point: ll.LatLng(worker.latitude, worker.longitude);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Worker Name and Status Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B0068), Color(0xFF1E1F30)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: statusColor.withAlpha(102), // 40% opacity
                            blurRadius: 15
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(worker.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Email: ${worker.email}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 15),
                        Chip(
                          label: Text(worker.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: statusColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- GOOGLE MAP SECTION ---
                  const Text('Live Location Map', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 10),

                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(77), // 30% opacity
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: ll.LatLng(worker.latitude, worker.longitude),
                          initialZoom: 15,
                        ),
                        children: [
                          // ---- MAP TILE LAYER ----
                          TileLayer(
                            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            userAgentPackageName: 'com.workhive.app',
                          ),

                          // ---- WORKER MARKER ----
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 40,
                                height: 40,
                                point: ll.LatLng(worker.latitude, worker.longitude),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),

                          // ---- GEOFENCE CIRCLE ----
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                radius: 500, // meters
                                point: ll.LatLng(37.7750, -122.4200),
                                color: Colors.blue.withOpacity(0.2),
                                borderStrokeWidth: 2,
                                borderColor: Colors.blue,
            )
            ],
            ),
            ],
            ),
            ),
            ),




            // Live Location Data
                  const Text('Live Coordinates (Updated every 10s)', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white30),

                  _buildDetailRow('Latitude', worker.latitude.toStringAsFixed(6), Colors.pinkAccent),
                  _buildDetailRow('Longitude', worker.longitude.toStringAsFixed(6), Colors.pinkAccent),

                  const SizedBox(height: 30),

                  // Geofence & Security Info
                  const Text('Operational Security', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white30),

                  _buildDetailRow(
                    'Geofence Status',
                    worker.isInsideGeofence ? 'INSIDE COMPANY RANGE' : 'OUTSIDE COMPANY RANGE',
                    worker.isInsideGeofence ? Colors.lightBlueAccent : Colors.orangeAccent,
                  ),
                  _buildDetailRow(
                    'Blockchain Integrity',
                    'Simulated: Data Immutable', // Simulate Blockchain check
                    Colors.greenAccent,
                  ),
                  _buildDetailRow(
                    'Last Update',
                    'Every 10 seconds',
                    Colors.white70,
                  ),


                ],
              ),
            );
          },
        ),
      );
    }
  
    Widget _buildDetailRow(String label, String value, Color valueColor) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
  
  class WorkerDetailPage extends StatelessWidget {
    final Worker worker;
  
    const WorkerDetailPage({super.key, required this.worker});
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple.withValues(alpha: 0.8),
          title: Text(
            worker.name,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                child: Text(
                  worker.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                worker.role,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Location Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white30),
            _buildDetailRow('Latitude', worker.latitude.toStringAsFixed(6),
                Colors.pinkAccent),
            _buildDetailRow('Longitude', worker.longitude.toStringAsFixed(6),
                Colors.pinkAccent),
            const SizedBox(height: 30),
            const Text(
              'Operational Security',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white30),
            _buildDetailRow(
              'Geofence Status',
              worker.isInsideGeofence
                  ? 'INSIDE COMPANY RANGE'
                  : 'OUTSIDE COMPANY RANGE',
              worker.isInsideGeofence
                  ? Colors.lightBlueAccent
                  : Colors.orangeAccent,
            ),
            _buildDetailRow(
              'Blockchain Integrity',
              'Simulated: Data Immutable',
              Colors.greenAccent,
            ),
            _buildDetailRow(
              'Last Update',
              'Every 10 seconds',
              Colors.white70,
            ),
          ],
        ),
      );
    }
  
    Widget _buildDetailRow(String label, String value, Color valueColor) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
  
  // ✅ Fixed typo
  const String auraSecret = "aura_secret";
