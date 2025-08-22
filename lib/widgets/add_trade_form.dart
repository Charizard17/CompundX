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
  bool _isExpanded = false;

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

      // Auto-collapse after successful submission
      setState(() {
        _isExpanded = false;
      });

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Trade',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (!_isExpanded)
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _isExpanded = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'ADD TRADE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_isExpanded) ...[
                    IconButton(
                      onPressed: () => setState(() => _isExpanded = false),
                      icon: const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white70,
                      ),
                      iconSize: 20,
                    ),
                  ] else ...[
                    IconButton(
                      onPressed: () => setState(() => _isExpanded = true),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                      ),
                      iconSize: 20,
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Expandable form content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? null : 0,
            child: _isExpanded ? _buildExpandedForm() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Row 1: Essential fields in compact layout
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildCompactTextField(
                  _symbolController,
                  'Symbol',
                  required: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(flex: 1, child: _buildCompactTypeDropdown()),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildCompactNumberField(
                  _leverageController,
                  'Lev',
                  isInteger: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildCompactNumberField(
                  _entryPriceController,
                  'Entry Price',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Secondary fields
          Row(
            children: [
              Expanded(child: _buildCompactDateField()),
              const SizedBox(width: 8),
              Expanded(child: _buildCompactTimeField()),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactNumberField(
                  _quantityController,
                  'Quantity',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactNumberField(
                  _pnlController,
                  'PNL',
                  allowNegative: true,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                height: 40,
                child: ElevatedButton(
                  onPressed: _submitTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'ADD',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDateField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      onTap: _selectDate,
      style: const TextStyle(color: Colors.white, fontSize: 11),
      decoration: InputDecoration(
        labelText: 'Date',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 9),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purpleAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        suffixIcon: const Icon(
          Icons.calendar_today,
          color: Colors.white70,
          size: 14,
        ),
      ),
      validator: (value) => value?.isEmpty == true ? 'Required' : null,
    );
  }

  Widget _buildCompactTimeField() {
    return TextFormField(
      controller: _timeController,
      readOnly: true,
      onTap: _selectTime,
      style: const TextStyle(color: Colors.white, fontSize: 11),
      decoration: InputDecoration(
        labelText: 'Time',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 9),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purpleAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        suffixIcon: const Icon(
          Icons.access_time,
          color: Colors.white70,
          size: 14,
        ),
      ),
      validator: (value) => value?.isEmpty == true ? 'Required' : null,
    );
  }

  Widget _buildCompactTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 11),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 9),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purpleAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      validator: required
          ? (value) => value?.isEmpty == true ? 'Required' : null
          : null,
    );
  }

  Widget _buildCompactNumberField(
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
      style: const TextStyle(color: Colors.white, fontSize: 11),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 9),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purpleAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (isInteger) {
          if (int.tryParse(value) == null) return 'Invalid';
        } else {
          if (double.tryParse(value) == null) return 'Invalid';
        }
        return null;
      },
    );
  }

  Widget _buildCompactTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      style: const TextStyle(color: Colors.white, fontSize: 11),
      dropdownColor: Colors.grey.shade800,
      decoration: InputDecoration(
        labelText: 'Type',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 9),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purpleAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      items: ['Long', 'Short'].map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type, style: const TextStyle(fontSize: 11)),
        );
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
