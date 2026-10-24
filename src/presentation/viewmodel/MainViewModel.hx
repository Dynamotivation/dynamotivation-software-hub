package presentation.viewmodel;

import application.dto.RegisterItemCommand;
import application.usecase.ListItemsUseCase;
import application.usecase.RegisterItemUseCase;
import domain.model.HubItem;

/**
 * ViewModel for the MainView.
 * Connects UI actions to Application Use Cases without coupling the domain to UI widgets.
 */
class MainViewModel {
    final registerItemUseCase:RegisterItemUseCase;
    final listItemsUseCase:ListItemsUseCase;

    public function new(registerItemUseCase:RegisterItemUseCase, listItemsUseCase:ListItemsUseCase) {
        this.registerItemUseCase = registerItemUseCase;
        this.listItemsUseCase = listItemsUseCase;
    }

    public function registerItem(name:String):Null<HubItem> {
        try {
            var cmd = new RegisterItemCommand(name);
            return registerItemUseCase.execute(cmd);
        } catch (e:Dynamic) {
            #if debug
            Sys.println('Validation or execution error: ' + Std.string(e));
            #end
            return null;
        }
    }

    public function getItems():Array<HubItem> {
        return listItemsUseCase.execute();
    }
}
