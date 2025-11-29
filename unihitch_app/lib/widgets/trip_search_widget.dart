import 'package:flutter/material.dart';

class TripSearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final Function(String) onSortChange;
  final Function(bool) onFilterCash;
  final List<String> destinosPopulares;

  const TripSearchWidget({
    super.key,
    required this.onSearch,
    required this.onSortChange,
    required this.onFilterCash,
    this.destinosPopulares = const [],
  });

  @override
  State<TripSearchWidget> createState() => _TripSearchWidgetState();
}

class _TripSearchWidgetState extends State<TripSearchWidget> {
  final _searchController = TextEditingController();
  String _selectedSort = 'fecha_hora';
  bool _onlyCash = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de búsqueda
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '¿A dónde vas?',
                  prefixIcon: const Icon(Icons.search, color: Colors.purple),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearch('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  widget.onSearch(value);
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              // Filtros de ordenamiento
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSortChip(
                        'Más pronto', 'fecha_hora', Icons.access_time),
                    const SizedBox(width: 8),
                    _buildSortChip(
                        'Menor precio', 'precio', Icons.attach_money),
                    const SizedBox(width: 8),
                    _buildSortChip(
                        'Mejor calificado', 'calificacion', Icons.star),
                    const SizedBox(width: 8),
                    _buildSortChip(
                        'Más asientos', 'asientos', Icons.event_seat),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: Icon(Icons.local_atm,
                          size: 18,
                          color: _onlyCash ? Colors.white : Colors.green),
                      label: const Text('Solo efectivo'),
                      selected: _onlyCash,
                      onSelected: (selected) {
                        setState(() {
                          _onlyCash = selected;
                        });
                        widget.onFilterCash(selected);
                      },
                      selectedColor: Colors.green,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: _onlyCash ? Colors.white : Colors.black87,
                        fontWeight:
                            _onlyCash ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Destinos populares (solo si no hay búsqueda activa)
        if (_searchController.text.isEmpty &&
            widget.destinosPopulares.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Destinos populares',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.destinosPopulares.map((destino) {
                    return ActionChip(
                      avatar: const Icon(Icons.location_on, size: 18),
                      label: Text(destino),
                      onPressed: () {
                        _searchController.text = destino;
                        widget.onSearch(destino);
                        setState(() {});
                      },
                      backgroundColor: Colors.purple.shade50,
                      labelStyle: const TextStyle(color: Colors.purple),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = _selectedSort == value;
    return FilterChip(
      avatar: Icon(icon,
          size: 18, color: isSelected ? Colors.white : Colors.purple),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSort = value;
        });
        widget.onSortChange(value);
      },
      selectedColor: Colors.purple,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
