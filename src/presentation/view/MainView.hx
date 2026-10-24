package presentation.view;

import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import presentation.style.PlatformStyleManager;
import presentation.viewmodel.MainViewModel;

/**
 * Main application view.
 * Built declaratively from XML and decorated with platform-specific styles.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/views/main_view.xml"))
class MainView extends VBox {
    final viewModel:MainViewModel;

    public function new(viewModel:MainViewModel) {
        super();
        this.viewModel = viewModel;

        // Apply platform-specific styling classes and quirks (margins, paddings, fonts)
        PlatformStyleManager.applyToRoot(this);

        setupEventHandlers();
        refreshItems();
    }

    function setupEventHandlers():Void {
        registerButton.onClick = function(e:MouseEvent) {
            var rawText = itemNameInput.text;
            if (rawText != null && StringTools.trim(rawText).length > 0) {
                var item = viewModel.registerItem(rawText);
                if (item != null) {
                    itemNameInput.text = "";
                    refreshItems();
                }
            }
        };

        refreshButton.onClick = function(e:MouseEvent) {
            refreshItems();
        };
    }

    public function refreshItems():Void {
        itemListView.dataSource.clear();
        var items = viewModel.getItems();
        for (item in items) {
            itemListView.dataSource.add({
                text: '${item.name} [${item.status}] - ID: ${item.id}'
            });
        }
    }
}
