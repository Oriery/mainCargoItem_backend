using {oriery.mci as mci} from '../db/main';

@path: '/main'
service MainService {

  entity ItemClass as projection on mci.ItemClass;
  entity Item      as projection on mci.Item {
    *,
    content: Association to many Item on content.containedIn = $self,
  }

  entity Transport2RootItem as projection on mci.Transport2RootItem;
  
  entity Transport as projection on mci.Transport {
    *,
    content: Association to many Transport2RootItem on content.transport = $self,
  }
    actions {
      action updateMcis();
    }

}
