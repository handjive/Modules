remove-module -Force handjive.Everything                 
remove-module -Force handjive.ChainScript
remove-module -Force handjive.Collections
remove-module -Force handjive.MessageBuilder             
remove-module -Force handjive.Config
remove-module -Force handjive.Foundation
remove-module -Force handjive.misc                       
remove-module -Force handjive.ValueHolder

import-module handjive.Everything                 
import-module handjive.MessageBuilder             
import-module handjive.ChainScript
import-module handjive.Collections
import-module handjive.Config
import-module handjive.Foundation
import-module handjive.misc                       
import-module handjive.ValueHolder

get-module
