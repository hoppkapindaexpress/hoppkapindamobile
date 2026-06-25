path = 'C:/hopp_kapinda/lib/features/courier/courier_delivery_screen.dart'
content = open(path, encoding='utf-8').read()

old = """  @override
  void initState() {
    super.initState();
    _startSelfLocation();
    _refreshRoute();
    _buildIcons();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(courierOrderDetailProvider(widget.orderId));
      _refreshRoute();
    });
  }"""

new = """  @override
  void initState() {
    super.initState();
    _startSelfLocation();
    _refreshRoute();
    _buildIcons();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(courierOrderDetailProvider(widget.orderId));
      _refreshRoute();
    });
    // Ekran açıldığında sipariş zaten on_the_way ise konum takibini başlat
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final order = await OrderService.getOrder(widget.orderId);
        if (order.status == 'on_the_way' && mounted) {
          await ref
              .read(locationStreamProvider.notifier)
              .startTracking(orderId: widget.orderId);
        }
      } catch (_) {}
    });
  }"""

if old in content:
    content = content.replace(old, new)
    open(path, 'w', encoding='utf-8').write(content)
    print('OK')
else:
    print('NOT FOUND')
