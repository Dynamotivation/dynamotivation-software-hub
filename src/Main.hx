package;

import application.usecase.ListItemsUseCase;
import application.usecase.RegisterItemUseCase;
import haxe.ui.HaxeUIApp;
import infrastructure.persistence.InMemoryHubItemRepository;
import presentation.style.PlatformStyleManager;
import presentation.view.MainView;
import presentation.viewmodel.MainViewModel;

/**
 * Composition Root
 * Wires the Domain, Application, Infrastructure, and Presentation layers.
 */
class Main {
    public static function main() {
        var app = new HaxeUIApp();

        app.ready(function() {
            // 1. Initialize platform-specific stylesheet rules
            PlatformStyleManager.initializePlatformStyles();

            // 2. Instantiate Infrastructure Adapters
            var repository = new InMemoryHubItemRepository();

            // 3. Instantiate Application Use Cases
            var registerItemUseCase = new RegisterItemUseCase(repository);
            var listItemsUseCase = new ListItemsUseCase(repository);

            // 4. Instantiate Presentation ViewModel & View
            var viewModel = new MainViewModel(registerItemUseCase, listItemsUseCase);
            var mainView = new MainView(viewModel);

            // Seed sample data for preview
            viewModel.registerItem("Jumpmaster Engine Core");
            viewModel.registerItem("Cross-Platform Asset Pipeline");
            mainView.refreshItems();

            // 5. Mount root component and start GUI event loop
            app.addComponent(mainView);
            app.start();
        });
    }
}
