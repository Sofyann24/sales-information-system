import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  // Opsional: Untuk integrasi filter kategori/chip di bawah search bar
  final Widget? categoryFilter;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Cari...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.categoryFilter,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _searchController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _searchController = widget.controller ?? TextEditingController();
    _hasText = _searchController.text.isNotEmpty;

    _searchController.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    setState(() {
      _hasText = _searchController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _searchController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: TextField(
            controller: _searchController,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              suffixIcon: _hasText
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        if (widget.onChanged != null) widget.onChanged!('');
                        if (widget.onClear != null) widget.onClear!();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFF4D96FF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(
                  color: Color(0xFF4D96FF),
                  width: 2,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ),

        // Render filter kategori secara fleksibel jika ada
        if (widget.categoryFilter != null) ...[
          const SizedBox(height: 8),
          widget.categoryFilter!,
        ],
      ],
    );
  }
}
