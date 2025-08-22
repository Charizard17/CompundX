import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/trade_service.dart';

class AddTradeForm extends StatefulWidget {
  const AddTradeForm({Key? key}) : super(key: key);

  @override
  State<AddTradeForm> createState() => _AddTradeFormState();
}

class _AddTradeFormState extends State<AddTradeForm> {
  final _formKey = GlobalKey<FormState>();
  final TradeService _tradeService = TradeService();

  // Form controllers
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _exchangeController = TextEditingController(text: 'Bybit');
  final _symbolController = TextEditingController();
  final _leverageController = TextEditingController();
  final _entryPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _pnlController = TextEditingController();

  String _selectedType = 'Long';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _updateDateTimeControllers();
  }

  void _updateDateTimeControllers() {
    _dateController.text =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    _timeController.text =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.purpleAccent,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateTimeControllers();
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.purpleAccent,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _updateDateTimeControllers();
      });
    }
  }

  void _submitTrade() {
    if (_formKey.currentState!.validate()) {
      _tradeService.addTrade(
        date: _selectedDate,
        time: _timeController.text,
        exchange: _exchangeController.text,
        symbol: _symbolController.text.toUpperCase(),
        type: _selectedType,
        leverage: int.parse(_leverageController.text),
        entryPrice: double.parse(_entryPriceController.text),
        quantity: double.parse(_quantityController.text),
        pnl: double.parse(_pnlController.text),
      );

      // Clear form
      _symbolController.clear();
      _leverageController.clear();
      _entryPriceController.clear();
      _quantityController.clear();
      _pnlController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trade added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Trade',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Row 1: Date, Time, Exchange, Symbol
            Row(
              children: [
                Expanded(child: _buildDateField()),
                const SizedBox(width: 12),
                Expanded(child: _buildTimeField()),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(_exchangeController, 'Exchange'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _symbolController,
                    'Symbol',
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Type, Leverage, Entry Price, Quantity
            Row(
              children: [
                Expanded(child: _buildTypeDropdown()),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    _leverageController,
                    'Leverage',
                    isInteger: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    _entryPriceController,
                    'Entry Price',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(_quantityController, 'Quantity'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: PNL and ADD button
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    _pnlController,
                    'PNL',
                    allowNegative: true,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitTrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'ADD',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      onTap: _selectDate,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        labelText: 'Date',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purpleAccent),
        ),
        suffixIcon: const Icon(
          Icons.calendar_today,
          color: Colors.white70,
          size: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildTimeField() {
    return TextFormField(
      controller: _timeController,
      readOnly: true,
      onTap: _selectTime,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        labelText: 'Time',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purpleAccent),
        ),
        suffixIcon: const Icon(
          Icons.access_time,
          color: Colors.white70,
          size: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purpleAccent),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label, {
    bool isInteger = false,
    bool allowNegative = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      inputFormatters: [
        if (isInteger)
          FilteringTextInputFormatter.digitsOnly
        else
          FilteringTextInputFormatter.allow(
            RegExp(allowNegative ? r'^-?\d*\.?\d*' : r'^\d*\.?\d*'),
          ),
      ],
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purpleAccent),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (isInteger) {
          if (int.tryParse(value) == null) {
            return 'Invalid';
          }
        } else {
          if (double.tryParse(value) == null) {
            return 'Invalid';
          }
        }
        return null;
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      dropdownColor: Colors.grey.shade800,
      decoration: InputDecoration(
        labelText: 'Type',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purpleAccent),
        ),
      ),
      items: ['Long', 'Short'].map((String type) {
        return DropdownMenuItem<String>(value: type, child: Text(type));
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedType = newValue!;
        });
      },
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _exchangeController.dispose();
    _symbolController.dispose();
    _leverageController.dispose();
    _entryPriceController.dispose();
    _quantityController.dispose();
    _pnlController.dispose();
    super.dispose();
  }
}
