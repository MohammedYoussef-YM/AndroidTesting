import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shop/auth_repositories/customException.dart';
import 'package:shop/controllers/authController.dart';
import 'package:shop/controllers/itemListController.dart';
import 'package:shop/models/itemModel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
// lkdsajf dlskjf
  //lkjlkjl jlkj lkjl lkj
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final authConrollerState = useProvider(authControllerProvider.state);
    final itemListFilter = useProvider(itemListFilterProvider);
    final isObtainedFilter = itemListFilter.state == ItemListFilter.obtained;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        leading: authConrollerState != null
            ? IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => context.read(authControllerProvider).signOut(),
              )
            : null,
        actions: [
          IconButton(
              icon: Icon(
                isObtainedFilter ? Icons.check_circle : Icons.check_box,
              ),
              onPressed: () => itemListFilter.state = isObtainedFilter
                  ? ItemListFilter.all
                  : ItemListFilter.obtained)
        ],
      ),
      body: ProviderListener(
        provider: itemListExceptionProvider,
        onChange: (
          BuildContext context,
          StateController<CustomException?> customException,
        ) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(customException.state!.message!),
          ));
        },
        child: const ItemList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddItemDialog.show(context, Item.empty()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

final currentItem = ScopedProvider<Item>((_) => throw UnimplementedError());

class ItemList extends HookWidget {
  const ItemList({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final itemListState = useProvider(itemListControllerProvider.state);
    final filteredItemList = useProvider(filteredItemListProvider);
    return itemListState.when(
        data: (items) => items.isEmpty
            ? const Center(
                child: Text(
                  'Tap + to add an item',
                  style: TextStyle(fontSize: 20),
                ),
              )
            : ListView.builder(
                // To checkBox animation does not rebuild when list updates
                itemCount: filteredItemList.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = filteredItemList[index];
                  return ProviderScope(
                      overrides: [currentItem.overrideWithValue(item)],
                      child: ItemTile());
                }),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ItemListError(
              message: error is CustomException
                  ? error.message
                  : "Something went wrong",
            ));
  }
}

class ItemTile extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final item = useProvider(currentItem);
    return ListTile(
      key: ValueKey(item.id),
      title: Text(item.name),
      trailing: Checkbox(
        value: item.obtained,
        onChanged: (value) => context
            .read(itemListControllerProvider)
            .updateItem(updatedItem: item.copyWith(obtained: item.obtained)),
      ),
      onTap: () => AddItemDialog.show(context, item),
      onLongPress: () =>
          context.read(itemListControllerProvider).deleteItem(itemId: item.id!),
    );
  }
}

class ItemListError extends StatelessWidget {
  final String? message;
  const ItemListError({Key? key, required this.message}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message!, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context
                .read(itemListControllerProvider)
                .retrieveItems(isRefreshing: true),
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }
}

class AddItemDialog extends HookWidget {
  static void show(BuildContext context, Item item) {
    showDialog(
        context: context, builder: (context) => AddItemDialog(item: item));
  }

  final Item item;
  const AddItemDialog({Key? key, required this.item}) : super(key: key);
  bool get isUpdateing => item.id != null;

  @override
  Widget build(BuildContext context) {
    final textContoller = useTextEditingController(text: item.name);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textContoller,
              autofocus: true,
              decoration: const InputDecoration(hintText: "Item name"),
            ),
            SizedBox(height: 12.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  isUpdateing
                      ? context.read(itemListControllerProvider).updateItem(
                              updatedItem: item.copyWith(
                            name: textContoller.text.trim(),
                            obtained: item.obtained,
                          ))
                      : context
                          .read(itemListControllerProvider)
                          .addItem(name: textContoller.text.trim());
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  primary: isUpdateing
                      ? Colors.orange
                      : Theme.of(context).primaryColor,
                ),
                child: Text(isUpdateing ? "Update" : 'Add'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
