import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class FilterModal extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final String selectedDateFilter;
  final double minAmount;
  final double maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String) onCategoryChanged;
  final Function(String) onDateFilterChanged;
  final Function(double, double) onAmountRangeChanged;
  final Function(DateTime?, DateTime?) onDateRangeChanged;
  final Function onResetFilters;
  final int resultsCount;

  const FilterModal({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.selectedDateFilter,
    required this.minAmount,
    required this.maxAmount,
    required this.startDate,
    required this.endDate,
    required this.onCategoryChanged,
    required this.onDateFilterChanged,
    required this.onAmountRangeChanged,
    required this.onDateRangeChanged,
    required this.onResetFilters,
    required this.resultsCount,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late String _selectedCategory;
  late String _selectedDateFilter;
  late double _minAmount;
  late double _maxAmount;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _selectedDateFilter = widget.selectedDateFilter;
    _minAmount = widget.minAmount;
    _maxAmount = widget.maxAmount;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )} COP';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Si se selecciona fecha personalizada, cambiar el filtro
        _selectedDateFilter = 'custom';
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        // Si se selecciona fecha personalizada, cambiar el filtro
        _selectedDateFilter = 'custom';
      });
    }
  }

  void _applyChanges() {
    widget.onCategoryChanged(_selectedCategory);
    widget.onDateFilterChanged(_selectedDateFilter);
    widget.onAmountRangeChanged(_minAmount, _maxAmount);
    widget.onDateRangeChanged(_startDate, _endDate);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'all';
      _selectedDateFilter = 'all';
      _minAmount = 0;
      _maxAmount = 10000000;
      _startDate = null;
      _endDate = null;
    });
    widget.onResetFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.fondo,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del modal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros Avanzados',
                  style: TextStyle(
                    color: AppTheme.texto,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppTheme.texto,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.resultsCount} resultados encontrados',
              style: TextStyle(
                color: AppTheme.texto.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Contenido desplazable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filtro por categoría
                    _buildFilterSection(
                      title: 'Categoría',
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Selecciona una categoría',
                          labelStyle: TextStyle(color: AppTheme.texto.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.botonesFondo),
                          ),
                          filled: true,
                          fillColor: AppTheme.card1Fondo,
                        ),
                        style: TextStyle(color: AppTheme.texto),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Todas las categorías'),
                          ),
                          ...widget.categories.where((category) => category != 'all').map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                style: TextStyle(color: AppTheme.texto),
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Filtro por período
                    _buildFilterSection(
                      title: 'Período de Tiempo',
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedDateFilter,
                            decoration: InputDecoration(
                              labelText: 'Selecciona un período',
                              labelStyle: TextStyle(color: AppTheme.texto.withOpacity(0.7)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.botonesFondo),
                              ),
                              filled: true,
                              fillColor: AppTheme.card1Fondo,
                            ),
                            style: TextStyle(color: AppTheme.texto),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Todos los tiempos')),
                              DropdownMenuItem(value: 'today', child: Text('Hoy')),
                              DropdownMenuItem(value: 'week', child: Text('Esta semana')),
                              DropdownMenuItem(value: 'month', child: Text('Este mes')),
                              DropdownMenuItem(value: 'year', child: Text('Este año')),
                              DropdownMenuItem(value: 'custom', child: Text('Rango personalizado')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedDateFilter = value!;
                                // Si no es custom, limpiar las fechas
                                if (value != 'custom') {
                                  _startDate = null;
                                  _endDate = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Selector de rango de fechas (solo visible cuando es custom)
                          if (_selectedDateFilter == 'custom') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fecha inicial',
                                        style: TextStyle(
                                          color: AppTheme.texto,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () => _selectStartDate(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.card1Fondo,
                                          foregroundColor: AppTheme.texto,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
                                          ),
                                          minimumSize: const Size(double.infinity, 50),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(_formatDate(_startDate)),
                                            Icon(
                                              Icons.calendar_today,
                                              color: AppTheme.texto.withOpacity(0.6),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fecha final',
                                        style: TextStyle(
                                          color: AppTheme.texto,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () => _selectEndDate(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.card1Fondo,
                                          foregroundColor: AppTheme.texto,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
                                          ),
                                          minimumSize: const Size(double.infinity, 50),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(_formatDate(_endDate)),
                                            Icon(
                                              Icons.calendar_today,
                                              color: AppTheme.texto.withOpacity(0.6),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_startDate != null && _endDate != null)
                              Text(
                                'Rango seleccionado: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                                style: TextStyle(
                                  color: AppTheme.botonesFondo,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Filtro por rango de montos
                    _buildFilterSection(
                      title: 'Rango de Montos',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatCurrency(_minAmount),
                                style: TextStyle(
                                  color: AppTheme.texto,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatCurrency(_maxAmount),
                                style: TextStyle(
                                  color: AppTheme.texto,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RangeSlider(
                            values: RangeValues(_minAmount, _maxAmount),
                            min: 0,
                            max: 10000000,
                            divisions: 20,
                            activeColor: AppTheme.botonesFondo,
                            inactiveColor: AppTheme.texto.withOpacity(0.2),
                            labels: RangeLabels(
                              _formatCurrency(_minAmount),
                              _formatCurrency(_maxAmount),
                            ),
                            onChanged: (values) {
                              setState(() {
                                _minAmount = values.start;
                                _maxAmount = values.end;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selecciona el rango de montos que deseas visualizar',
                            style: TextStyle(
                              color: AppTheme.texto.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.texto,
                      side: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Restablecer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _applyChanges();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.botonesFondo,
                      foregroundColor: AppTheme.botonesTexto,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Aplicar Filtros'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.texto,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}