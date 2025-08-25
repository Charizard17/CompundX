import 'package:compundx/constants/app_constants.dart';
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
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.textPrimaryColor,
              surface: AppConstants.disabledColor,
              onSurface: AppConstants.textPrimaryColor,
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
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.textPrimaryColor,
              surface: AppConstants.disabledColor,
              onSurface: AppConstants.textPrimaryColor,
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
      // Parse PNL - if empty or invalid, default to 0 (open trade)
      double? pnlValue;
      if (_pnlController.text.isNotEmpty) {
        pnlValue = double.tryParse(_pnlController.text);
      }

      _tradeService.addTrade(
        date: _selectedDate,
        time: _timeController.text,
        exchange: _exchangeController.text,
        symbol: _symbolController.text.toUpperCase(),
        type: _selectedType,
        leverage: int.parse(_leverageController.text),
        entryPrice: double.parse(_entryPriceController.text),
        quantity: double.parse(_quantityController.text),
        pnl: pnlValue, // Will default to 0 if null
      );

      // Clear form
      _symbolController.clear();
      _leverageController.clear();
      _entryPriceController.clear();
      _quantityController.clear();
      _pnlController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pnlValue == null
                ? 'Open trade added successfully!'
                : 'Closed trade added successfully!',
          ),
          backgroundColor: AppConstants.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.cardColor),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Trade',
              style: TextStyle(
                color: AppConstants.textPrimaryColor,
                fontSize: AppConstants.headerFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Row 1: Symbol, Type, Leverage, Entry Price
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _symbolController,
                    'Symbol',
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildTypeDropdown()),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    _leverageController,
                    'Leverage',
                    isInteger: true,
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    _entryPriceController,
                    'Entry Price',
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Date, Time, Quantity, PNL
            Row(
              children: [
                Expanded(child: _buildDateField()),
                const SizedBox(width: 12),
                Expanded(child: _buildTimeField()),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    _quantityController,
                    'Quantity',
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    _pnlController,
                    'PNL (Optional)',
                    allowNegative: true,
                    required: false, // PNL is now optional
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: ADD button
            Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: 100,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitTrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: AppConstants.textPrimaryColor,
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
      style: const TextStyle(
        color: AppConstants.textPrimaryColor,
        fontSize: AppConstants.smallFontSize,
      ),
      decoration: InputDecoration(
        labelText: 'Date',
        labelStyle: const TextStyle(
          color: AppConstants.textSecondaryColor,
          fontSize: AppConstants.smallFontSize,
        ),
        filled: true,
        fillColor: AppConstants.cardColor,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
        suffixIcon: const Icon(
          Icons.calendar_today,
          color: AppConstants.textSecondaryColor,
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
      style: const TextStyle(
        color: AppConstants.textPrimaryColor,
        fontSize: AppConstants.smallFontSize,
      ),
      decoration: InputDecoration(
        labelText: 'Time',
        labelStyle: const TextStyle(
          color: AppConstants.textSecondaryColor,
          fontSize: AppConstants.smallFontSize,
        ),
        filled: true,
        fillColor: AppConstants.cardColor,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
        suffixIcon: const Icon(
          Icons.access_time,
          color: AppConstants.textSecondaryColor,
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
      style: const TextStyle(
        color: AppConstants.textPrimaryColor,
        fontSize: AppConstants.smallFontSize,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppConstants.textSecondaryColor,
          fontSize: AppConstants.smallFontSize,
        ),
        filled: true,
        fillColor: AppConstants.cardColor,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.primaryColor),
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
    bool required = true,
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
      style: const TextStyle(
        color: AppConstants.textPrimaryColor,
        fontSize: AppConstants.smallFontSize,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppConstants.textSecondaryColor,
          fontSize: AppConstants.smallFontSize,
        ),
        filled: true,
        fillColor: AppConstants.cardColor,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Required';
        }
        if (value != null && value.isNotEmpty) {
          if (isInteger) {
            if (int.tryParse(value) == null) {
              return 'Invalid';
            }
          } else {
            if (double.tryParse(value) == null) {
              return 'Invalid';
            }
          }
        }
        return null;
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      style: const TextStyle(
        color: AppConstants.textPrimaryColor,
        fontSize: AppConstants.smallFontSize,
      ),
      dropdownColor: AppConstants.cardColor,
      decoration: InputDecoration(
        labelText: 'Type',
        labelStyle: const TextStyle(
          color: AppConstants.textSecondaryColor,
          fontSize: AppConstants.smallFontSize,
        ),
        filled: true,
        fillColor: AppConstants.cardColor,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.primaryColor),
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
