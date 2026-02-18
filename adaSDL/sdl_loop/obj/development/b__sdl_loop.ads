pragma Warnings (Off);
pragma Ada_95;
with System;
with System.Parameters;
with System.Secondary_Stack;
package ada_main is

   gnat_argc : Integer;
   gnat_argv : System.Address;
   gnat_envp : System.Address;

   pragma Import (C, gnat_argc);
   pragma Import (C, gnat_argv);
   pragma Import (C, gnat_envp);

   gnat_exit_status : Integer;
   pragma Import (C, gnat_exit_status);

   GNAT_Version : constant String :=
                    "GNAT Version: 14.2.0" & ASCII.NUL;
   pragma Export (C, GNAT_Version, "__gnat_version");

   GNAT_Version_Address : constant System.Address := GNAT_Version'Address;
   pragma Export (C, GNAT_Version_Address, "__gnat_version_address");

   Ada_Main_Program_Name : constant String := "_ada_sdl_loop" & ASCII.NUL;
   pragma Export (C, Ada_Main_Program_Name, "__gnat_ada_main_program_name");

   procedure adainit;
   pragma Export (C, adainit, "adainit");

   procedure adafinal;
   pragma Export (C, adafinal, "adafinal");

   function main
     (argc : Integer;
      argv : System.Address;
      envp : System.Address)
      return Integer;
   pragma Export (C, main, "main");

   type Version_32 is mod 2 ** 32;
   u00001 : constant Version_32 := 16#4b8d0326#;
   pragma Export (C, u00001, "sdl_loopB");
   u00002 : constant Version_32 := 16#30305195#;
   pragma Export (C, u00002, "system__standard_libraryB");
   u00003 : constant Version_32 := 16#0626cc96#;
   pragma Export (C, u00003, "system__standard_libraryS");
   u00004 : constant Version_32 := 16#a201b8c5#;
   pragma Export (C, u00004, "ada__strings__text_buffersB");
   u00005 : constant Version_32 := 16#a7cfd09b#;
   pragma Export (C, u00005, "ada__strings__text_buffersS");
   u00006 : constant Version_32 := 16#76789da1#;
   pragma Export (C, u00006, "adaS");
   u00007 : constant Version_32 := 16#e6d4fa36#;
   pragma Export (C, u00007, "ada__stringsS");
   u00008 : constant Version_32 := 16#14286b0f#;
   pragma Export (C, u00008, "systemS");
   u00009 : constant Version_32 := 16#c71e6c8a#;
   pragma Export (C, u00009, "system__exception_tableB");
   u00010 : constant Version_32 := 16#99031d16#;
   pragma Export (C, u00010, "system__exception_tableS");
   u00011 : constant Version_32 := 16#fd5f5f4c#;
   pragma Export (C, u00011, "system__soft_linksB");
   u00012 : constant Version_32 := 16#455c24f2#;
   pragma Export (C, u00012, "system__soft_linksS");
   u00013 : constant Version_32 := 16#524f7d04#;
   pragma Export (C, u00013, "system__secondary_stackB");
   u00014 : constant Version_32 := 16#bae33a03#;
   pragma Export (C, u00014, "system__secondary_stackS");
   u00015 : constant Version_32 := 16#9a5d1b93#;
   pragma Export (C, u00015, "ada__exceptionsB");
   u00016 : constant Version_32 := 16#64d9391c#;
   pragma Export (C, u00016, "ada__exceptionsS");
   u00017 : constant Version_32 := 16#0740df23#;
   pragma Export (C, u00017, "ada__exceptions__last_chance_handlerB");
   u00018 : constant Version_32 := 16#a028f72d#;
   pragma Export (C, u00018, "ada__exceptions__last_chance_handlerS");
   u00019 : constant Version_32 := 16#268dd43d#;
   pragma Export (C, u00019, "system__exceptionsS");
   u00020 : constant Version_32 := 16#69416224#;
   pragma Export (C, u00020, "system__exceptions__machineB");
   u00021 : constant Version_32 := 16#46355a4a#;
   pragma Export (C, u00021, "system__exceptions__machineS");
   u00022 : constant Version_32 := 16#7706238d#;
   pragma Export (C, u00022, "system__exceptions_debugB");
   u00023 : constant Version_32 := 16#2426335c#;
   pragma Export (C, u00023, "system__exceptions_debugS");
   u00024 : constant Version_32 := 16#36b7284e#;
   pragma Export (C, u00024, "system__img_intS");
   u00025 : constant Version_32 := 16#f2c63a02#;
   pragma Export (C, u00025, "ada__numericsS");
   u00026 : constant Version_32 := 16#174f5472#;
   pragma Export (C, u00026, "ada__numerics__big_numbersS");
   u00027 : constant Version_32 := 16#ee021456#;
   pragma Export (C, u00027, "system__unsigned_typesS");
   u00028 : constant Version_32 := 16#d8f6bfe7#;
   pragma Export (C, u00028, "system__storage_elementsS");
   u00029 : constant Version_32 := 16#5c7d9c20#;
   pragma Export (C, u00029, "system__tracebackB");
   u00030 : constant Version_32 := 16#92b29fb2#;
   pragma Export (C, u00030, "system__tracebackS");
   u00031 : constant Version_32 := 16#5f6b6486#;
   pragma Export (C, u00031, "system__traceback_entriesB");
   u00032 : constant Version_32 := 16#dc34d483#;
   pragma Export (C, u00032, "system__traceback_entriesS");
   u00033 : constant Version_32 := 16#b27c8a69#;
   pragma Export (C, u00033, "system__traceback__symbolicB");
   u00034 : constant Version_32 := 16#140ceb78#;
   pragma Export (C, u00034, "system__traceback__symbolicS");
   u00035 : constant Version_32 := 16#179d7d28#;
   pragma Export (C, u00035, "ada__containersS");
   u00036 : constant Version_32 := 16#701f9d88#;
   pragma Export (C, u00036, "ada__exceptions__tracebackB");
   u00037 : constant Version_32 := 16#26ed0985#;
   pragma Export (C, u00037, "ada__exceptions__tracebackS");
   u00038 : constant Version_32 := 16#9111f9c1#;
   pragma Export (C, u00038, "interfacesS");
   u00039 : constant Version_32 := 16#0390ef72#;
   pragma Export (C, u00039, "interfaces__cB");
   u00040 : constant Version_32 := 16#1a6d7811#;
   pragma Export (C, u00040, "interfaces__cS");
   u00041 : constant Version_32 := 16#a43efea2#;
   pragma Export (C, u00041, "system__parametersB");
   u00042 : constant Version_32 := 16#21bf971e#;
   pragma Export (C, u00042, "system__parametersS");
   u00043 : constant Version_32 := 16#0978786d#;
   pragma Export (C, u00043, "system__bounded_stringsB");
   u00044 : constant Version_32 := 16#63d54a16#;
   pragma Export (C, u00044, "system__bounded_stringsS");
   u00045 : constant Version_32 := 16#9f0c0c80#;
   pragma Export (C, u00045, "system__crtlS");
   u00046 : constant Version_32 := 16#a604bd9c#;
   pragma Export (C, u00046, "system__dwarf_linesB");
   u00047 : constant Version_32 := 16#f38e5e19#;
   pragma Export (C, u00047, "system__dwarf_linesS");
   u00048 : constant Version_32 := 16#5b4659fa#;
   pragma Export (C, u00048, "ada__charactersS");
   u00049 : constant Version_32 := 16#9de61c25#;
   pragma Export (C, u00049, "ada__characters__handlingB");
   u00050 : constant Version_32 := 16#729cc5db#;
   pragma Export (C, u00050, "ada__characters__handlingS");
   u00051 : constant Version_32 := 16#cde9ea2d#;
   pragma Export (C, u00051, "ada__characters__latin_1S");
   u00052 : constant Version_32 := 16#c5e1e773#;
   pragma Export (C, u00052, "ada__strings__mapsB");
   u00053 : constant Version_32 := 16#6feaa257#;
   pragma Export (C, u00053, "ada__strings__mapsS");
   u00054 : constant Version_32 := 16#b451a498#;
   pragma Export (C, u00054, "system__bit_opsB");
   u00055 : constant Version_32 := 16#d9dbc733#;
   pragma Export (C, u00055, "system__bit_opsS");
   u00056 : constant Version_32 := 16#b459efcb#;
   pragma Export (C, u00056, "ada__strings__maps__constantsS");
   u00057 : constant Version_32 := 16#a0d3d22b#;
   pragma Export (C, u00057, "system__address_imageB");
   u00058 : constant Version_32 := 16#b5c4f635#;
   pragma Export (C, u00058, "system__address_imageS");
   u00059 : constant Version_32 := 16#7da15eb1#;
   pragma Export (C, u00059, "system__img_unsS");
   u00060 : constant Version_32 := 16#20ec7aa3#;
   pragma Export (C, u00060, "system__ioB");
   u00061 : constant Version_32 := 16#8a6a9c40#;
   pragma Export (C, u00061, "system__ioS");
   u00062 : constant Version_32 := 16#e15ca368#;
   pragma Export (C, u00062, "system__mmapB");
   u00063 : constant Version_32 := 16#da9a152c#;
   pragma Export (C, u00063, "system__mmapS");
   u00064 : constant Version_32 := 16#367911c4#;
   pragma Export (C, u00064, "ada__io_exceptionsS");
   u00065 : constant Version_32 := 16#dd82c35a#;
   pragma Export (C, u00065, "system__mmap__os_interfaceB");
   u00066 : constant Version_32 := 16#37fd3b64#;
   pragma Export (C, u00066, "system__mmap__os_interfaceS");
   u00067 : constant Version_32 := 16#c8a05a18#;
   pragma Export (C, u00067, "system__mmap__unixS");
   u00068 : constant Version_32 := 16#29c68ba2#;
   pragma Export (C, u00068, "system__os_libB");
   u00069 : constant Version_32 := 16#ee44bb50#;
   pragma Export (C, u00069, "system__os_libS");
   u00070 : constant Version_32 := 16#94d23d25#;
   pragma Export (C, u00070, "system__atomic_operations__test_and_setB");
   u00071 : constant Version_32 := 16#57acee8e#;
   pragma Export (C, u00071, "system__atomic_operations__test_and_setS");
   u00072 : constant Version_32 := 16#d34b112a#;
   pragma Export (C, u00072, "system__atomic_operationsS");
   u00073 : constant Version_32 := 16#553a519e#;
   pragma Export (C, u00073, "system__atomic_primitivesB");
   u00074 : constant Version_32 := 16#5f776048#;
   pragma Export (C, u00074, "system__atomic_primitivesS");
   u00075 : constant Version_32 := 16#b98923bf#;
   pragma Export (C, u00075, "system__case_utilB");
   u00076 : constant Version_32 := 16#db3bbc5a#;
   pragma Export (C, u00076, "system__case_utilS");
   u00077 : constant Version_32 := 16#256dbbe5#;
   pragma Export (C, u00077, "system__stringsB");
   u00078 : constant Version_32 := 16#8faa6b17#;
   pragma Export (C, u00078, "system__stringsS");
   u00079 : constant Version_32 := 16#edf7b7b1#;
   pragma Export (C, u00079, "system__object_readerB");
   u00080 : constant Version_32 := 16#87571f07#;
   pragma Export (C, u00080, "system__object_readerS");
   u00081 : constant Version_32 := 16#75406883#;
   pragma Export (C, u00081, "system__val_lliS");
   u00082 : constant Version_32 := 16#838eea00#;
   pragma Export (C, u00082, "system__val_lluS");
   u00083 : constant Version_32 := 16#47d9a892#;
   pragma Export (C, u00083, "system__sparkS");
   u00084 : constant Version_32 := 16#a571a4dc#;
   pragma Export (C, u00084, "system__spark__cut_operationsB");
   u00085 : constant Version_32 := 16#629c0fb7#;
   pragma Export (C, u00085, "system__spark__cut_operationsS");
   u00086 : constant Version_32 := 16#1bac5121#;
   pragma Export (C, u00086, "system__val_utilB");
   u00087 : constant Version_32 := 16#b851cf14#;
   pragma Export (C, u00087, "system__val_utilS");
   u00088 : constant Version_32 := 16#bad10b33#;
   pragma Export (C, u00088, "system__exception_tracesB");
   u00089 : constant Version_32 := 16#f8b00269#;
   pragma Export (C, u00089, "system__exception_tracesS");
   u00090 : constant Version_32 := 16#fd158a37#;
   pragma Export (C, u00090, "system__wch_conB");
   u00091 : constant Version_32 := 16#cd2b486c#;
   pragma Export (C, u00091, "system__wch_conS");
   u00092 : constant Version_32 := 16#5c289972#;
   pragma Export (C, u00092, "system__wch_stwB");
   u00093 : constant Version_32 := 16#e03a646d#;
   pragma Export (C, u00093, "system__wch_stwS");
   u00094 : constant Version_32 := 16#7cd63de5#;
   pragma Export (C, u00094, "system__wch_cnvB");
   u00095 : constant Version_32 := 16#cbeb821c#;
   pragma Export (C, u00095, "system__wch_cnvS");
   u00096 : constant Version_32 := 16#e538de43#;
   pragma Export (C, u00096, "system__wch_jisB");
   u00097 : constant Version_32 := 16#7e5ce036#;
   pragma Export (C, u00097, "system__wch_jisS");
   u00098 : constant Version_32 := 16#0286ce9f#;
   pragma Export (C, u00098, "system__soft_links__initializeB");
   u00099 : constant Version_32 := 16#2ed17187#;
   pragma Export (C, u00099, "system__soft_links__initializeS");
   u00100 : constant Version_32 := 16#8599b27b#;
   pragma Export (C, u00100, "system__stack_checkingB");
   u00101 : constant Version_32 := 16#d3777e19#;
   pragma Export (C, u00101, "system__stack_checkingS");
   u00102 : constant Version_32 := 16#8b7604c4#;
   pragma Export (C, u00102, "ada__strings__utf_encodingB");
   u00103 : constant Version_32 := 16#c9e86997#;
   pragma Export (C, u00103, "ada__strings__utf_encodingS");
   u00104 : constant Version_32 := 16#bb780f45#;
   pragma Export (C, u00104, "ada__strings__utf_encoding__stringsB");
   u00105 : constant Version_32 := 16#b85ff4b6#;
   pragma Export (C, u00105, "ada__strings__utf_encoding__stringsS");
   u00106 : constant Version_32 := 16#d1d1ed0b#;
   pragma Export (C, u00106, "ada__strings__utf_encoding__wide_stringsB");
   u00107 : constant Version_32 := 16#5678478f#;
   pragma Export (C, u00107, "ada__strings__utf_encoding__wide_stringsS");
   u00108 : constant Version_32 := 16#c2b98963#;
   pragma Export (C, u00108, "ada__strings__utf_encoding__wide_wide_stringsB");
   u00109 : constant Version_32 := 16#d7af3358#;
   pragma Export (C, u00109, "ada__strings__utf_encoding__wide_wide_stringsS");
   u00110 : constant Version_32 := 16#0d5e09a4#;
   pragma Export (C, u00110, "ada__tagsB");
   u00111 : constant Version_32 := 16#2a9756e0#;
   pragma Export (C, u00111, "ada__tagsS");
   u00112 : constant Version_32 := 16#3548d972#;
   pragma Export (C, u00112, "system__htableB");
   u00113 : constant Version_32 := 16#95f133e4#;
   pragma Export (C, u00113, "system__htableS");
   u00114 : constant Version_32 := 16#1f1abe38#;
   pragma Export (C, u00114, "system__string_hashB");
   u00115 : constant Version_32 := 16#32b4b39b#;
   pragma Export (C, u00115, "system__string_hashS");
   u00116 : constant Version_32 := 16#0b0c4bff#;
   pragma Export (C, u00116, "applicationB");
   u00117 : constant Version_32 := 16#8427167c#;
   pragma Export (C, u00117, "applicationS");
   u00118 : constant Version_32 := 16#0716e5a4#;
   pragma Export (C, u00118, "sdlB");
   u00119 : constant Version_32 := 16#81437614#;
   pragma Export (C, u00119, "sdlS");
   u00120 : constant Version_32 := 16#31fb55ee#;
   pragma Export (C, u00120, "sdl__eventsS");
   u00121 : constant Version_32 := 16#afd11956#;
   pragma Export (C, u00121, "sdl__events__eventsB");
   u00122 : constant Version_32 := 16#fcab2aaa#;
   pragma Export (C, u00122, "sdl__events__eventsS");
   u00123 : constant Version_32 := 16#c9eefe9c#;
   pragma Export (C, u00123, "sdl__errorB");
   u00124 : constant Version_32 := 16#e250ecea#;
   pragma Export (C, u00124, "sdl__errorS");
   u00125 : constant Version_32 := 16#58c21abc#;
   pragma Export (C, u00125, "interfaces__c__stringsB");
   u00126 : constant Version_32 := 16#fecad76a#;
   pragma Export (C, u00126, "interfaces__c__stringsS");
   u00127 : constant Version_32 := 16#1afae323#;
   pragma Export (C, u00127, "sdl__events__controllersS");
   u00128 : constant Version_32 := 16#c0a27217#;
   pragma Export (C, u00128, "sdl__events__joysticksB");
   u00129 : constant Version_32 := 16#5ebd2213#;
   pragma Export (C, u00129, "sdl__events__joysticksS");
   u00130 : constant Version_32 := 16#60f2d66f#;
   pragma Export (C, u00130, "sdl__events__filesS");
   u00131 : constant Version_32 := 16#3ea51472#;
   pragma Export (C, u00131, "sdl__events__keyboardsB");
   u00132 : constant Version_32 := 16#5ca6d9a6#;
   pragma Export (C, u00132, "sdl__events__keyboardsS");
   u00133 : constant Version_32 := 16#7ffd88c8#;
   pragma Export (C, u00133, "sdl__videoB");
   u00134 : constant Version_32 := 16#63c56cb0#;
   pragma Export (C, u00134, "sdl__videoS");
   u00135 : constant Version_32 := 16#784ca59c#;
   pragma Export (C, u00135, "sdl__video__windowsB");
   u00136 : constant Version_32 := 16#30d7b2a1#;
   pragma Export (C, u00136, "sdl__video__windowsS");
   u00137 : constant Version_32 := 16#e259c480#;
   pragma Export (C, u00137, "system__assertionsB");
   u00138 : constant Version_32 := 16#322b1494#;
   pragma Export (C, u00138, "system__assertionsS");
   u00139 : constant Version_32 := 16#8b2c6428#;
   pragma Export (C, u00139, "ada__assertionsB");
   u00140 : constant Version_32 := 16#cc3ec2fd#;
   pragma Export (C, u00140, "ada__assertionsS");
   u00141 : constant Version_32 := 16#b9e0ae25#;
   pragma Export (C, u00141, "system__finalization_mastersB");
   u00142 : constant Version_32 := 16#a6db6891#;
   pragma Export (C, u00142, "system__finalization_mastersS");
   u00143 : constant Version_32 := 16#86c56e5a#;
   pragma Export (C, u00143, "ada__finalizationS");
   u00144 : constant Version_32 := 16#b4f41810#;
   pragma Export (C, u00144, "ada__streamsB");
   u00145 : constant Version_32 := 16#67e31212#;
   pragma Export (C, u00145, "ada__streamsS");
   u00146 : constant Version_32 := 16#05222263#;
   pragma Export (C, u00146, "system__put_imagesB");
   u00147 : constant Version_32 := 16#08866c10#;
   pragma Export (C, u00147, "system__put_imagesS");
   u00148 : constant Version_32 := 16#22b9eb9f#;
   pragma Export (C, u00148, "ada__strings__text_buffers__utilsB");
   u00149 : constant Version_32 := 16#89062ac3#;
   pragma Export (C, u00149, "ada__strings__text_buffers__utilsS");
   u00150 : constant Version_32 := 16#95817ed8#;
   pragma Export (C, u00150, "system__finalization_rootB");
   u00151 : constant Version_32 := 16#5bda189f#;
   pragma Export (C, u00151, "system__finalization_rootS");
   u00152 : constant Version_32 := 16#35d6ef80#;
   pragma Export (C, u00152, "system__storage_poolsB");
   u00153 : constant Version_32 := 16#8e431254#;
   pragma Export (C, u00153, "system__storage_poolsS");
   u00154 : constant Version_32 := 16#8b0ace09#;
   pragma Export (C, u00154, "system__storage_pools__subpoolsB");
   u00155 : constant Version_32 := 16#50a294f1#;
   pragma Export (C, u00155, "system__storage_pools__subpoolsS");
   u00156 : constant Version_32 := 16#252fe4d9#;
   pragma Export (C, u00156, "system__storage_pools__subpools__finalizationB");
   u00157 : constant Version_32 := 16#562129f7#;
   pragma Export (C, u00157, "system__storage_pools__subpools__finalizationS");
   u00158 : constant Version_32 := 16#4055c7cd#;
   pragma Export (C, u00158, "sdl__c_pointersS");
   u00159 : constant Version_32 := 16#dd7f75da#;
   pragma Export (C, u00159, "sdl__video__displaysB");
   u00160 : constant Version_32 := 16#1ee6fa14#;
   pragma Export (C, u00160, "sdl__video__displaysS");
   u00161 : constant Version_32 := 16#e84b94c1#;
   pragma Export (C, u00161, "sdl__video__pixel_formatsB");
   u00162 : constant Version_32 := 16#5b43530f#;
   pragma Export (C, u00162, "sdl__video__pixel_formatsS");
   u00163 : constant Version_32 := 16#c08a65fd#;
   pragma Export (C, u00163, "sdl__video__palettesB");
   u00164 : constant Version_32 := 16#988882c6#;
   pragma Export (C, u00164, "sdl__video__palettesS");
   u00165 : constant Version_32 := 16#3f686d0f#;
   pragma Export (C, u00165, "system__pool_globalB");
   u00166 : constant Version_32 := 16#a07c1f1e#;
   pragma Export (C, u00166, "system__pool_globalS");
   u00167 : constant Version_32 := 16#8f2423cb#;
   pragma Export (C, u00167, "system__memoryB");
   u00168 : constant Version_32 := 16#0cbcf715#;
   pragma Export (C, u00168, "system__memoryS");
   u00169 : constant Version_32 := 16#d0926081#;
   pragma Export (C, u00169, "system__taskingB");
   u00170 : constant Version_32 := 16#830ed04a#;
   pragma Export (C, u00170, "system__taskingS");
   u00171 : constant Version_32 := 16#be15cda8#;
   pragma Export (C, u00171, "system__task_primitivesS");
   u00172 : constant Version_32 := 16#72136539#;
   pragma Export (C, u00172, "system__os_interfaceB");
   u00173 : constant Version_32 := 16#6a1d7316#;
   pragma Export (C, u00173, "system__os_interfaceS");
   u00174 : constant Version_32 := 16#bff98b5c#;
   pragma Export (C, u00174, "system__linuxS");
   u00175 : constant Version_32 := 16#b4f669b5#;
   pragma Export (C, u00175, "system__os_constantsS");
   u00176 : constant Version_32 := 16#16de8de8#;
   pragma Export (C, u00176, "system__task_primitives__operationsB");
   u00177 : constant Version_32 := 16#1a81091a#;
   pragma Export (C, u00177, "system__task_primitives__operationsS");
   u00178 : constant Version_32 := 16#9ebeb40e#;
   pragma Export (C, u00178, "system__interrupt_managementB");
   u00179 : constant Version_32 := 16#f000fc35#;
   pragma Export (C, u00179, "system__interrupt_managementS");
   u00180 : constant Version_32 := 16#3053a91b#;
   pragma Export (C, u00180, "system__multiprocessorsB");
   u00181 : constant Version_32 := 16#2c84f47c#;
   pragma Export (C, u00181, "system__multiprocessorsS");
   u00182 : constant Version_32 := 16#d172d809#;
   pragma Export (C, u00182, "system__os_primitivesB");
   u00183 : constant Version_32 := 16#13d50ef9#;
   pragma Export (C, u00183, "system__os_primitivesS");
   u00184 : constant Version_32 := 16#4ee862d1#;
   pragma Export (C, u00184, "system__task_infoB");
   u00185 : constant Version_32 := 16#a250823b#;
   pragma Export (C, u00185, "system__task_infoS");
   u00186 : constant Version_32 := 16#0e54f198#;
   pragma Export (C, u00186, "system__tasking__debugB");
   u00187 : constant Version_32 := 16#aeb4df49#;
   pragma Export (C, u00187, "system__tasking__debugS");
   u00188 : constant Version_32 := 16#ca878138#;
   pragma Export (C, u00188, "system__concat_2B");
   u00189 : constant Version_32 := 16#a1d318f8#;
   pragma Export (C, u00189, "system__concat_2S");
   u00190 : constant Version_32 := 16#752a67ed#;
   pragma Export (C, u00190, "system__concat_3B");
   u00191 : constant Version_32 := 16#9e5272ad#;
   pragma Export (C, u00191, "system__concat_3S");
   u00192 : constant Version_32 := 16#5eeebe35#;
   pragma Export (C, u00192, "system__img_lliS");
   u00193 : constant Version_32 := 16#3066cab0#;
   pragma Export (C, u00193, "system__stack_usageB");
   u00194 : constant Version_32 := 16#4a68f31e#;
   pragma Export (C, u00194, "system__stack_usageS");
   u00195 : constant Version_32 := 16#8bbcb17b#;
   pragma Export (C, u00195, "sdl__video__rectanglesB");
   u00196 : constant Version_32 := 16#81a76bf0#;
   pragma Export (C, u00196, "sdl__video__rectanglesS");
   u00197 : constant Version_32 := 16#8c68cef0#;
   pragma Export (C, u00197, "sdl__video__surfacesB");
   u00198 : constant Version_32 := 16#2b8ee06a#;
   pragma Export (C, u00198, "sdl__video__surfacesS");
   u00199 : constant Version_32 := 16#d79db92c#;
   pragma Export (C, u00199, "system__return_stackS");
   u00200 : constant Version_32 := 16#8356fb7a#;
   pragma Export (C, u00200, "system__stream_attributesB");
   u00201 : constant Version_32 := 16#5e1f8be2#;
   pragma Export (C, u00201, "system__stream_attributesS");
   u00202 : constant Version_32 := 16#4ea7f13e#;
   pragma Export (C, u00202, "system__stream_attributes__xdrB");
   u00203 : constant Version_32 := 16#14c199f1#;
   pragma Export (C, u00203, "system__stream_attributes__xdrS");
   u00204 : constant Version_32 := 16#d71ab463#;
   pragma Export (C, u00204, "system__fat_fltS");
   u00205 : constant Version_32 := 16#f128bd6e#;
   pragma Export (C, u00205, "system__fat_lfltS");
   u00206 : constant Version_32 := 16#8bf81384#;
   pragma Export (C, u00206, "system__fat_llfS");
   u00207 : constant Version_32 := 16#acbcde40#;
   pragma Export (C, u00207, "sdl__events__miceS");
   u00208 : constant Version_32 := 16#5ddf0ad4#;
   pragma Export (C, u00208, "sdl__events__touchesS");
   u00209 : constant Version_32 := 16#3f621081#;
   pragma Export (C, u00209, "sdl__events__windowsS");
   u00210 : constant Version_32 := 16#036c1d3a#;
   pragma Export (C, u00210, "sdl__video__renderersB");
   u00211 : constant Version_32 := 16#55eecece#;
   pragma Export (C, u00211, "sdl__video__renderersS");
   u00212 : constant Version_32 := 16#55bc57b4#;
   pragma Export (C, u00212, "sdl__video__texturesB");
   u00213 : constant Version_32 := 16#ecd5fdff#;
   pragma Export (C, u00213, "sdl__video__texturesS");
   u00214 : constant Version_32 := 16#334014b4#;
   pragma Export (C, u00214, "sdl__video__pixelsS");
   u00215 : constant Version_32 := 16#f792467d#;
   pragma Export (C, u00215, "sdl__video__renderers__makersB");
   u00216 : constant Version_32 := 16#75f92e2f#;
   pragma Export (C, u00216, "sdl__video__renderers__makersS");
   u00217 : constant Version_32 := 16#3ccc86b8#;
   pragma Export (C, u00217, "sdl__video__windows__makersB");
   u00218 : constant Version_32 := 16#263f6111#;
   pragma Export (C, u00218, "sdl__video__windows__makersS");
   u00219 : constant Version_32 := 16#a4288827#;
   pragma Export (C, u00219, "transformS");

   --  BEGIN ELABORATION ORDER
   --  ada%s
   --  ada.characters%s
   --  ada.characters.latin_1%s
   --  interfaces%s
   --  system%s
   --  system.atomic_operations%s
   --  system.io%s
   --  system.io%b
   --  system.parameters%s
   --  system.parameters%b
   --  system.crtl%s
   --  system.os_primitives%s
   --  system.os_primitives%b
   --  system.spark%s
   --  system.spark.cut_operations%s
   --  system.spark.cut_operations%b
   --  system.storage_elements%s
   --  system.return_stack%s
   --  system.stack_checking%s
   --  system.stack_checking%b
   --  system.string_hash%s
   --  system.string_hash%b
   --  system.htable%s
   --  system.htable%b
   --  system.strings%s
   --  system.strings%b
   --  system.traceback_entries%s
   --  system.traceback_entries%b
   --  system.unsigned_types%s
   --  system.wch_con%s
   --  system.wch_con%b
   --  system.wch_jis%s
   --  system.wch_jis%b
   --  system.wch_cnv%s
   --  system.wch_cnv%b
   --  system.concat_2%s
   --  system.concat_2%b
   --  system.concat_3%s
   --  system.concat_3%b
   --  system.traceback%s
   --  system.traceback%b
   --  ada.characters.handling%s
   --  system.atomic_operations.test_and_set%s
   --  system.case_util%s
   --  system.os_lib%s
   --  system.secondary_stack%s
   --  system.standard_library%s
   --  ada.exceptions%s
   --  system.exceptions_debug%s
   --  system.exceptions_debug%b
   --  system.soft_links%s
   --  system.val_util%s
   --  system.val_util%b
   --  system.val_llu%s
   --  system.val_lli%s
   --  system.wch_stw%s
   --  system.wch_stw%b
   --  ada.exceptions.last_chance_handler%s
   --  ada.exceptions.last_chance_handler%b
   --  ada.exceptions.traceback%s
   --  ada.exceptions.traceback%b
   --  system.address_image%s
   --  system.address_image%b
   --  system.bit_ops%s
   --  system.bit_ops%b
   --  system.bounded_strings%s
   --  system.bounded_strings%b
   --  system.case_util%b
   --  system.exception_table%s
   --  system.exception_table%b
   --  ada.containers%s
   --  ada.io_exceptions%s
   --  ada.numerics%s
   --  ada.numerics.big_numbers%s
   --  ada.strings%s
   --  ada.strings.maps%s
   --  ada.strings.maps%b
   --  ada.strings.maps.constants%s
   --  interfaces.c%s
   --  interfaces.c%b
   --  system.atomic_primitives%s
   --  system.atomic_primitives%b
   --  system.exceptions%s
   --  system.exceptions.machine%s
   --  system.exceptions.machine%b
   --  ada.characters.handling%b
   --  system.atomic_operations.test_and_set%b
   --  system.exception_traces%s
   --  system.exception_traces%b
   --  system.img_int%s
   --  system.img_uns%s
   --  system.memory%s
   --  system.memory%b
   --  system.mmap%s
   --  system.mmap.os_interface%s
   --  system.mmap%b
   --  system.mmap.unix%s
   --  system.mmap.os_interface%b
   --  system.object_reader%s
   --  system.object_reader%b
   --  system.dwarf_lines%s
   --  system.dwarf_lines%b
   --  system.os_lib%b
   --  system.secondary_stack%b
   --  system.soft_links.initialize%s
   --  system.soft_links.initialize%b
   --  system.soft_links%b
   --  system.standard_library%b
   --  system.traceback.symbolic%s
   --  system.traceback.symbolic%b
   --  ada.exceptions%b
   --  ada.assertions%s
   --  ada.assertions%b
   --  ada.strings.utf_encoding%s
   --  ada.strings.utf_encoding%b
   --  ada.strings.utf_encoding.strings%s
   --  ada.strings.utf_encoding.strings%b
   --  ada.strings.utf_encoding.wide_strings%s
   --  ada.strings.utf_encoding.wide_strings%b
   --  ada.strings.utf_encoding.wide_wide_strings%s
   --  ada.strings.utf_encoding.wide_wide_strings%b
   --  ada.tags%s
   --  ada.tags%b
   --  ada.strings.text_buffers%s
   --  ada.strings.text_buffers%b
   --  ada.strings.text_buffers.utils%s
   --  ada.strings.text_buffers.utils%b
   --  interfaces.c.strings%s
   --  interfaces.c.strings%b
   --  system.fat_flt%s
   --  system.fat_lflt%s
   --  system.fat_llf%s
   --  system.linux%s
   --  system.multiprocessors%s
   --  system.multiprocessors%b
   --  system.os_constants%s
   --  system.os_interface%s
   --  system.os_interface%b
   --  system.put_images%s
   --  system.put_images%b
   --  ada.streams%s
   --  ada.streams%b
   --  system.finalization_root%s
   --  system.finalization_root%b
   --  ada.finalization%s
   --  system.stack_usage%s
   --  system.stack_usage%b
   --  system.storage_pools%s
   --  system.storage_pools%b
   --  system.finalization_masters%s
   --  system.finalization_masters%b
   --  system.storage_pools.subpools%s
   --  system.storage_pools.subpools.finalization%s
   --  system.storage_pools.subpools.finalization%b
   --  system.storage_pools.subpools%b
   --  system.stream_attributes%s
   --  system.stream_attributes.xdr%s
   --  system.stream_attributes.xdr%b
   --  system.stream_attributes%b
   --  system.task_info%s
   --  system.task_info%b
   --  system.task_primitives%s
   --  system.interrupt_management%s
   --  system.interrupt_management%b
   --  system.assertions%s
   --  system.assertions%b
   --  system.img_lli%s
   --  system.tasking%s
   --  system.task_primitives.operations%s
   --  system.tasking.debug%s
   --  system.tasking.debug%b
   --  system.task_primitives.operations%b
   --  system.tasking%b
   --  system.pool_global%s
   --  system.pool_global%b
   --  sdl%s
   --  sdl%b
   --  sdl.c_pointers%s
   --  sdl.error%s
   --  sdl.error%b
   --  sdl.events%s
   --  sdl.events.files%s
   --  sdl.events.joysticks%s
   --  sdl.events.joysticks%b
   --  sdl.events.controllers%s
   --  sdl.events.touches%s
   --  sdl.video%s
   --  sdl.video%b
   --  sdl.video.palettes%s
   --  sdl.video.palettes%b
   --  sdl.video.pixel_formats%s
   --  sdl.video.pixel_formats%b
   --  sdl.video.pixels%s
   --  sdl.video.rectangles%s
   --  sdl.video.rectangles%b
   --  sdl.video.displays%s
   --  sdl.video.displays%b
   --  sdl.video.surfaces%s
   --  sdl.video.surfaces%b
   --  sdl.video.textures%s
   --  sdl.video.textures%b
   --  sdl.video.windows%s
   --  sdl.video.windows%b
   --  sdl.events.keyboards%s
   --  sdl.events.keyboards%b
   --  sdl.events.mice%s
   --  sdl.events.windows%s
   --  sdl.events.events%s
   --  sdl.events.events%b
   --  sdl.video.renderers%s
   --  sdl.video.renderers%b
   --  sdl.video.renderers.makers%s
   --  sdl.video.renderers.makers%b
   --  sdl.video.windows.makers%s
   --  sdl.video.windows.makers%b
   --  transform%s
   --  application%s
   --  application%b
   --  sdl_loop%b
   --  END ELABORATION ORDER

end ada_main;
