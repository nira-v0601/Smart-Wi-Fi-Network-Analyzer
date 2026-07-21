import 'package:flutter/material.dart';

class IspLogoWidget extends StatefulWidget {
  final String? domain;
  final String? ispName;
  final double size;
  final Widget? fallbackWidget;

  const IspLogoWidget({
    super.key,
    this.domain,
    this.ispName,
    this.size = 20.0,
    this.fallbackWidget,
  });

  @override
  State<IspLogoWidget> createState() => _IspLogoWidgetState();
}

class _IspLogoWidgetState extends State<IspLogoWidget> {
  int _attempt = 0;
  late List<String> _urls;

  @override
  void initState() {
    super.initState();
    _initUrls();
  }

  @override
  void didUpdateWidget(covariant IspLogoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.domain != widget.domain || oldWidget.ispName != widget.ispName) {
      _initUrls();
    }
  }

  void _initUrls() {
    _attempt = 0;
    _urls = [];
    
    // First priority: provided domain
    if (widget.domain != null && widget.domain!.isNotEmpty) {
      _addUrlsForDomain(widget.domain!);
    }
    
    // Second priority: guess domain from ispName
    if (widget.ispName != null && widget.ispName!.isNotEmpty) {
      String name = widget.ispName!.toLowerCase();
      if (name != 'unknown' && name != 'unavailable') {
        // Remove common corporate suffixes
        name = name.replaceAll(RegExp(r'\b(ltd|limited|inc|llc|corp|corporation|pvt|private|telecom|broadband|communications|networks|services|fiber|fibernet)\b\.?'), '');
        // Remove non-alphanumeric
        String clean = name.replaceAll(RegExp(r'[^a-z0-9]'), '');
        
        if (clean.isNotEmpty) {
          // If domain wasn't provided or doesn't match the guessed one
          if (widget.domain == null || !widget.domain!.contains(clean)) {
             _addUrlsForDomain('$clean.com');
             _addUrlsForDomain('$clean.in');
             _addUrlsForDomain('$clean.net');
             _addUrlsForDomain('$clean.co.in');
          }
        }
      }
    }
  }

  void _addUrlsForDomain(String d) {
    _urls.add('https://logo.clearbit.com/$d');
    _urls.add('https://www.google.com/s2/favicons?domain=$d&sz=128');
  }

  @override
  Widget build(BuildContext context) {
    if (_urls.isEmpty || _attempt >= _urls.length) {
      return widget.fallbackWidget ?? 
             Icon(Icons.business, color: Theme.of(context).colorScheme.primary, size: widget.size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        _urls[_attempt],
        key: ValueKey(_urls[_attempt]),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Padding(
              padding: EdgeInsets.all(widget.size * 0.25),
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Schedule state update after the build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _attempt++;
              });
            }
          });
          // Show a temporary empty box while we try the next URL
          return SizedBox(width: widget.size, height: widget.size);
        },
      ),
    );
  }
}
