import 'package:compundx/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trade.dart';
import '../services/trade_service.dart';

class EditTradeDialog extends StatefulWidget {
  final Trade trade;

  const EditTradeDialog({Key? key, required this.trade}) : super(key: key);

  @override
  State<EditTradeDialog> createState() => _EditTradeDialogState();
}

class _EditTradeDialogState extends State<EditTradeDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TradeService _tradeService = TradeService();

  late TabController _tabController;

  // Form controllers
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _exchangeController;
  late final TextEditingController _symbolController;
  late final TextEditingController _leverageController;
  late final TextEditingController _entryPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _pnlController;
  late final TextEditingController _beforeScreenshotController;
  late final TextEditingController _afterScreenshotController;
  late final TextEditingController _notesController;

  late String _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize controllers with trade data
    _dateController = TextEditingController();
    _timeController = TextEditingController();
    _exchangeController = TextEditingController(text: widget.trade.exchange);
    _symbolController = TextEditingController(text: widget.trade.symbol);
    _leverageController = TextEditingController(
      text: widget.trade.leverage.toString(),
    );
    _entryPriceController = TextEditingController(
      text: widget.trade.entryPrice.toString(),
    );
    _quantityController = TextEditingController(
      text: widget.trade.quantity.toString(),
    );
    _pnlController = TextEditingController(
      text: widget.trade.pnl == 0 ? '' : widget.trade.pnl.toString(),
    );
    _beforeScreenshotController = TextEditingController(
      text: widget.trade.beforeScreenshotUrl ?? '',
    );
    _afterScreenshotController = TextEditingController(
      text: widget.trade.afterScreenshotUrl ?? '',
    );
    _notesController = TextEditingController(text: widget.trade.notes ?? '');

    _selectedType = widget.trade.type;
    _selectedDate = widget.trade.date;

    // Parse time from trade
    final timeParts = widget.trade.time.split(':');
    _selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

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

  void _updateTrade() {
    if (_formKey.currentState!.validate()) {
      // Parse PNL - if empty, keep as 0
      double? pnlValue;
      if (_pnlController.text.isNotEmpty) {
        pnlValue = double.tryParse(_pnlController.text) ?? 0.0;
      }

      _tradeService.updateTrade(
        widget.trade.id,
        date: _selectedDate,
        time: _timeController.text,
        exchange: _exchangeController.text,
        symbol: _symbolController.text.toUpperCase(),
        type: _selectedType,
        leverage: int.parse(_leverageController.text),
        entryPrice: double.parse(_entryPriceController.text),
        quantity: double.parse(_quantityController.text),
        pnl: pnlValue,
        beforeScreenshotUrl: _beforeScreenshotController.text.isNotEmpty
            ? _beforeScreenshotController.text
            : null,
        afterScreenshotUrl: _afterScreenshotController.text.isNotEmpty
            ? _afterScreenshotController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trade updated successfully!'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    }
  }

  void _deleteTrade() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text(
          'Delete Trade',
          style: TextStyle(color: AppConstants.textPrimaryColor),
        ),
        content: const Text(
          'Are you sure you want to delete this trade? This action cannot be undone.',
          style: TextStyle(color: AppConstants.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _tradeService.removeTrade(widget.trade.id);
              Navigator.of(context).pop(); // Close confirmation dialog
              Navigator.of(context).pop(); // Close edit dialog

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Trade deleted successfully!'),
                  backgroundColor: AppConstants.errorColor,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppConstants.surfaceColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Trade #${widget.trade.id}',
                    style: const TextStyle(
                      color: AppConstants.textPrimaryColor,
                      fontSize: AppConstants.largeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _deleteTrade,
                        icon: const Icon(
                          Icons.delete,
                          color: AppConstants.errorColor,
                        ),
                        tooltip: 'Delete Trade',
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppConstants.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Bar
              TabBar(
                controller: _tabController,
                labelColor: AppConstants.primaryColor,
                unselectedLabelColor: AppConstants.textSecondaryColor,
                indicatorColor: AppConstants.primaryColor,
                tabs: const [
                  Tab(text: 'Trade Details'),
                  Tab(text: 'Screenshots & Notes'),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTradeDetailsTab(),
                    _buildScreenshotsNotesTab(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _updateTrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: AppConstants.textPrimaryColor,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradeDetailsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
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
          const SizedBox(height: 16),

          // Row 2: Date, Time, Quantity, Exchange
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
              Expanded(child: _buildTextField(_exchangeController, 'Exchange')),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: PNL
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  _pnlController,
                  'PNL (Optional)',
                  allowNegative: true,
                  required: false,
                ),
              ),
              const Expanded(child: SizedBox()), // Empty space
              const Expanded(child: SizedBox()), // Empty space
              const Expanded(child: SizedBox()), // Empty space
            ],
          ),
          const SizedBox(height: 16),

          // Help text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppConstants.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppConstants.infoColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Leave PNL empty for open trades. When you close the trade, come back and add the PNL value.',
                    style: TextStyle(
                      color: AppConstants.textSecondaryColor,
                      fontSize: AppConstants.mediumFontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotsNotesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Screenshots',
            style: TextStyle(
              color: AppConstants.textPrimaryColor,
              fontSize: AppConstants.largeFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildTextField(
            _beforeScreenshotController,
            'Before Screenshot URL',
            hintText: 'https://example.com/before.png',
          ),
          const SizedBox(height: 12),

          _buildTextField(
            _afterScreenshotController,
            'After Screenshot URL',
            hintText: 'https://example.com/after.png',
          ),
          const SizedBox(height: 20),

          Text(
            'Notes',
            style: TextStyle(
              color: AppConstants.textPrimaryColor,
              fontSize: AppConstants.largeFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _notesController,
            maxLines: 5,
            style: const TextStyle(
              color: AppConstants.textPrimaryColor,
              fontSize: AppConstants.mediumFontSize,
            ),
            decoration: InputDecoration(
              labelText: 'Trade Notes',
              hintText: 'Add any notes about this trade...',
              hintStyle: TextStyle(color: AppConstants.textHintColor),
              labelStyle: const TextStyle(
                color: AppConstants.textSecondaryColor,
                fontSize: AppConstants.mediumFontSize,
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
          ),
          const SizedBox(height: 16),

          // Preview screenshots if URLs are provided
          if (_beforeScreenshotController.text.isNotEmpty ||
              _afterScreenshotController.text.isNotEmpty) ...[
            Text(
              'Preview',
              style: TextStyle(
                color: AppConstants.textPrimaryColor,
                fontSize: AppConstants.largeFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_beforeScreenshotController.text.isNotEmpty)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Before',
                          style: TextStyle(
                            color: AppConstants.textSecondaryColor,
                            fontSize: AppConstants.mediumFontSize,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppConstants.borderColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              _beforeScreenshotController.text,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppConstants.cardColor,
                                  child: const Center(
                                    child: Icon(
                                      Icons.error,
                                      color: AppConstants.errorColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_beforeScreenshotController.text.isNotEmpty &&
                    _afterScreenshotController.text.isNotEmpty)
                  const SizedBox(width: 12),
                if (_afterScreenshotController.text.isNotEmpty)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'After',
                          style: TextStyle(
                            color: AppConstants.textSecondaryColor,
                            fontSize: AppConstants.mediumFontSize,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppConstants.borderColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              _afterScreenshotController.text,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppConstants.cardColor,
                                  child: const Center(
                                    child: Icon(
                                      Icons.error,
                                      color: AppConstants.errorColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
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
        fontSize: AppConstants.mediumFontSize,
      ),
      decoration: InputDecoration(
        labelText: 'Date',
        labelStyle: const TextStyle(
          color: AppConstants.textSecondaryColor,
          fontSize: AppConstants.mediumFontSize,
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
          size: 18,
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
        fontSize: AppConstants.mediumFontSize,
      ),
      decoration: InputDecoration(
        labelText: 'Time',
        labelStyle: const TextStyle(
          color: AppConstants.textSecondaryColor,
          fontSize: AppConstants.mediumFontSize,
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
          size: 18,
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
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: AppConstants.textPrimaryColor,
        fontSize: AppConstants.mediumFontSize,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: AppConstants.textHintColor),
        labelStyle: const TextStyle(
          color: AppConstants.textSecondaryColor,
          fontSize: AppConstants.mediumFontSize,
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
        fontSize: AppConstants.mediumFontSize,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppConstants.textSecondaryColor,
          fontSize: AppConstants.mediumFontSize,
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
        fontSize: AppConstants.mediumFontSize,
      ),
      dropdownColor: AppConstants.cardColor,
      decoration: InputDecoration(
        labelText: 'Type',
        labelStyle: const TextStyle(
          color: AppConstants.textSecondaryColor,
          fontSize: AppConstants.mediumFontSize,
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
    _tabController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _exchangeController.dispose();
    _symbolController.dispose();
    _leverageController.dispose();
    _entryPriceController.dispose();
    _quantityController.dispose();
    _pnlController.dispose();
    _beforeScreenshotController.dispose();
    _afterScreenshotController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
