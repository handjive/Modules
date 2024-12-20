enum ESAPI_ERROR{
    OK	= 0
    ERROR_MEMORY = 1
    ERROR_IPC = 2
    REGISTERCLASSEX = 3
    ERROR_CREATEWINDOW = 4
    ERROR_CREATETHREAD = 5
    ERROR_INVALIDINDEX = 6
    ERROR_INVALIDCALL = 7
    ERROR_UNKNOWN = 8
}

[flags()] enum ESAPI_REQUEST{
    FILE_NAME = 0x00000001;
    PATH = 0x00000002;
    EXTENSION = 0x00000008;
    SIZE = 0x00000010;
    DATE_CREATED = 0x00000020;
    DATE_MODIFIED = 0x00000040;
    DATE_ACCESSED = 0x00000080;
    ATTRIBUTES = 0x00000100;
    #FULL_PATH_AND_FILE_NAME = 0x00000004;
    #FILE_LIST_FILE_NAME = 0x00000200;
    #DATE_RUN = 0x00000800;
    #DATE_RECENTLY_CHANGED = 0x00001000;
    #RUN_COUNT = 0x00000400;
}

enum ESAPI_SORT{
    NAME_ASCENDING = 1;
    NAME_DESCENDING = 2;
    PATH_ASCENDING = 3;
    PATH_DESCENDING = 4;
    SIZE_ASCENDING = 5;
    SIZE_DESCENDING = 6;
    EXTENSION_ASCENDING = 7;
    EXTENSION_DESCENDING = 8;
    TYPE_NAME_ASCENDING = 9;
    TYPE_NAME_DESCENDING = 10;
    ATTRIBUTES_ASCENDING = 15;
    ATTRIBUTES_DESCENDING = 16;
    FILE_LIST_FILENAME_ASCENDING = 17;
    FILE_LIST_FILENAME_DESCENDING = 18;
    RUN_COUNT_ASCENDING = 19;
    RUN_COUNT_DESCENDING = 20;
    DATE_CREATED_ASCENDING = 11;
    DATE_CREATED_DESCENDING = 12;
    DATE_MODIFIED_ASCENDING = 13;
    DATE_MODIFIED_DESCENDING = 14;
    DATE_RECENTLY_CHANGED_ASCENDING = 21;
    DATE_RECENTLY_CHANGED_DESCENDING = 22;
    DATE_ACCESSED_ASCENDING = 23;
    DATE_ACCESSED_DESCENDING = 24;
    DATE_RUN_ASCENDING = 25;
    DATE_RUN_DESCENDING = 26;
}
