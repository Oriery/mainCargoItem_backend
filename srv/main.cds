using {oriery.mci as mci} from '../db/main';

@path: '/main'
service MainService {

  entity ItemClass as projection on mci.ItemClass;
  entity Item      as projection on mci.Item;
  entity Transport as projection on mci.Transport
    actions {
      action updateMcis();
    }

}
