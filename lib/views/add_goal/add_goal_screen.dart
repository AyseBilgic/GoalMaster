// lib/views/add_goal/add_goal_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application1/models/goal.dart';
import 'package:flutter_application1/providers/auth_provider.dart';
import 'package:flutter_application1/providers/goal_provider.dart';
import 'package:provider/provider.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime? _selectedDate;
  double _progressValue = 0.0; // 0.0 - 1.0 arası

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose(); // super.dispose çağrılmalı
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), );
    if (picked != null && picked != _selectedDate) { setState(() { _selectedDate = picked; }); }
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoading = context.watch<GoalProvider>().isLoading;
    final errorMessage = context.watch<GoalProvider>().errorMessage;

    return Scaffold(
      appBar: AppBar( title: const Text('Yeni Hedef Ekle'), ),
      body: Padding( padding: const EdgeInsets.all(16.0),
        child: Form( key: _formKey,
          child: ListView( children: [
              TextFormField( controller: _titleController, decoration: const InputDecoration( labelText: 'Başlık *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag_outlined),),
                validator: (v)=>(v==null||v.trim().isEmpty)?'Başlık zorunludur.':null, ),
              const SizedBox(height: 16),
              TextFormField( controller: _descriptionController, decoration: const InputDecoration( labelText: 'Açıklama', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description_outlined),), maxLines: 4,),
              const SizedBox(height: 16),
              TextFormField( controller: _categoryController, decoration: const InputDecoration( labelText: 'Kategori', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_outlined),),),
              const SizedBox(height: 16),
              ListTile( leading: const Icon(Icons.calendar_today_outlined), title: Text(_selectedDate == null ? 'Hedef Tarih (İsteğe Bağlı)' : 'Hedef: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'), trailing: IconButton( icon: const Icon(Icons.edit_calendar_outlined), onPressed: () => _selectDate(context), tooltip: 'Tarih Seç',), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).colorScheme.outline)), onTap: () => _selectDate(context), ),
              const SizedBox(height: 20),
              Text('İlerleme: ${(_progressValue * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleMedium),
              Slider( value: _progressValue, min: 0.0, max: 1.0, divisions: 10, label: '${(_progressValue * 100).toStringAsFixed(0)}%', onChanged: (value) => setState(() => _progressValue = value), ),
              const SizedBox(height: 24),
              isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined), label: const Text('Hedefi Kaydet'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Düzeltme: Goal constructor'ı tam ve doğru
                    final newGoal = Goal(
                      goalId: 0, // ID backend'de atanacak
                      userId: authProvider.userId!, // Gerekli
                      title: _titleController.text.trim(), // Gerekli
                      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                      targetDate: _selectedDate,
                      isCompleted: _progressValue >= 1.0, // Gerekli (progress'e göre)
                      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
                      progress: _progressValue, // Gerekli (0.0-1.0)
                    );
                    bool success = await goalProvider.addGoal(newGoal);
                    if (success && mounted) {
                       Navigator.pop(context, true); // Başarılı olunca true dön
                    }
                  } else {
                    if(mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Lütfen formdaki hataları düzeltin.'), backgroundColor: Colors.orange,) ); }
                  }
                }, style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 12), textStyle: const TextStyle(fontSize: 16) ), ),
              if (errorMessage != null) ...[ const SizedBox(height: 16), Text( errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold), textAlign: TextAlign.center, ), ],
              const SizedBox(height: 20),
            ], ), ), ), );
  }
}