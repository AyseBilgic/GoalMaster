import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 1. intl paketi import edildi
import 'package:flutter_application1/models/goal.dart'; // 2. Goal sınıfı import edildi
import 'package:provider/provider.dart'; // 3. Provider import edildi
import 'package:flutter_application1/providers/goal_provider.dart'; // Provider import

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key}); // Düzeltildi: super.key kullanıldı

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState(); //Düzeltildi.
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime _dueDate = DateTime.now();
  String _category = 'Kişisel';

  final List<String> _categories = ['Kişisel', 'İş', 'Eğitim', 'Sağlık'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Hedef Ekle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Başlık'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir başlık girin';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 3,
                onSaved: (value) {
                  _description = value!;
                },
              ),
              ListTile(
                title: Text(
                  'Hedef Tarihi: ${DateFormat('dd.MM.yyyy').format(_dueDate)}',
                ), // DateFormat doğru kullanımı
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // print('Başlık: $_title, Açıklama: $_description, Tarih: $_dueDate, Kategori: $_category'); // Yorum satırı

                    final newGoal = Goal( // Goal sınıfı doğru kullanımı
                      id: '', // DatabaseService'de oluşturulacak
                      title: _title,
                      description: _description,
                      dueDate: _dueDate,
                      category: _category,
                    );

                    Provider.of<GoalProvider>(context, listen: false)
                        .addGoal(newGoal); // Provider kullanımı doğru

                    Navigator.pop(context); // Geri dön
                  }
                },
                child: const Text('Hedef Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}