import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class FilterModal extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final String selectedDateFilter;
  final double minAmount;
  final double maxAmount;
  final Function(String) onCategoryChanged;
  final Function(String) onDateFilterChanged;
  final Function(double, double) onAmountRangeChanged;
  final Function onResetFilters;
  final int resultsCount;

  const FilterModal({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.selectedDateFilter,
    required this.minAmount,
    required this.maxAmount,
    required this.onCategoryChanged,
    required this.onDateFilterChanged,
    required this.onAmountRangeChanged,
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

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _selectedDateFilter = widget.selectedDateFilter;
    _minAmount = widget.minAmount;
    _maxAmount = widget.maxAmount;
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )} COP';
  }

  void _applyChanges() {
    widget.onCategoryChanged(_selectedCategory);
    widget.onDateFilterChanged(_selectedDateFilter);
    widget.onAmountRangeChanged(_minAmount, _maxAmount);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'all';
      _selectedDateFilter = 'all';
      _minAmount = 0;
      _maxAmount = 10000000;
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
                      child: DropdownButtonFormField<String>(
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
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDateFilter = value!;
                          });
                        },
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