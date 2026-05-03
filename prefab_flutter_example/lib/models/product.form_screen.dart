// GENERATED CODE - DO NOT MODIFY BY HAND
//
// **************************************************************************
// FormScreenGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'product.dart';
import 'product.provider.dart';

class ProductCreateScreen extends ConsumerStatefulWidget {
  const ProductCreateScreen({super.key});

  @override
  ConsumerState<ProductCreateScreen> createState() =>
      _ProductCreateScreenState();
}

class _ProductCreateScreenState extends ConsumerState<ProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final n = double.tryParse(value ?? '');
                if (n == null || n <= 0) return 'Must be a positive number';
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final entity = Product(
                    id: 0,
                    name: _nameController.text,
                    price: double.parse(_priceController.text),
                    description: _descriptionController.text,
                  );
                  await ref.read(productsProvider.notifier).create(entity);
                  if (context.mounted) context.pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductEditScreen extends ConsumerStatefulWidget {
  final Object id;

  const ProductEditScreen({super.key, required this.id});

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _prefilled = false;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _prefillControllers(Product item) {
    _nameController.text = item.name;
    _priceController.text = item.price.toString();
    _descriptionController.text = item.description;
  }

  @override
  Widget build(BuildContext context) {
    final asyncItem = ref.watch(productDetailProvider(widget.id));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: asyncItem.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (item) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final n = double.tryParse(value ?? '');
                  if (n == null || n <= 0) return 'Must be a positive number';
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final entity = Product(
                      id: item.id,
                      name: _nameController.text,
                      price: double.parse(_priceController.text),
                      description: _descriptionController.text,
                    );
                    await ref.read(productsProvider.notifier).update(entity);
                    if (context.mounted) context.pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
