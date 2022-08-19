# - Try to find the AAX SDK
# Once done this will define
# 
#  AAXSDK_FOUND - system has AAX SDK
#  AAXSDK_HOME - the AAX SDK root directory

set(AAXSDK_X64 0)
set(AAXSDK_LIB_SUFFIX "")

if (CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(AAXSDK_X64 1)
	if(MSVC)
    	set(AAXSDK_LIB_SUFFIX "_x64")
    endif()
endif()


set(results "")

# if the variable is already defined, set it as the first hint
if(DEFINED AAXSDK_HOME)
	set(results ${results} "${AAXSDK_HOME}")
endif()

foreach(basedir "C:/" "D:/" "$ENV{HOME}/" "${CMAKE_CURRENT_SOURCE_DIR}/" "${CMAKE_CURRENT_LIST_DIR}/")
	foreach(level "" "../" "../../")
		foreach(suffix "" "SDKs/")
            foreach(pattern "AAX_SDK_2p3p2" "AAX_SDK_2p3p1" "AAX_SDK" "AAX")
				file(GLOB results1 "${basedir}${level}${suffix}${pattern}*")
				set(results ${results} ${results1})
            endforeach()
		endforeach()
	endforeach()
endforeach()

foreach(f ${results})
  if(IS_DIRECTORY ${f})
    set(AAXSDK_SEARCH_PATHS_HINT ${AAXSDK_SEARCH_PATHS_HINT} ${f})
  endif()
endforeach()

find_path(AAXSDK_HOME
	  Interfaces/AAX.h
	HINTS
    	${AAXSDK_SEARCH_PATHS_HINT}
)


# handle the QUIETLY and REQUIRED arguments and set AAXSDK_FOUND to TRUE if 
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(AAXSDK DEFAULT_MSG AAXSDK_HOME AAXSDK_X64)
mark_as_advanced(AAXSDK_HOME)

# export an AAXSDK::AAXSDK target
if(AAXSDK_FOUND)
	set(AAXSDK_INCLUDE_DIRS 
        "${AAXSDK_HOME}" 
        "${AAXSDK_HOME}/Interfaces" 
        "${AAXSDK_HOME}/Interfaces/ACF"
	)

    find_library(AAXSDK_LIB_DEBUG
        NAMES 
            libAAXLibrary_libcpp.a
            AAXLibrary${AAXSDK_LIB_SUFFIX}_D.lib
        PATHS
            "${AAXSDK_HOME}/Libs/Debug/"
        NO_DEFAULT_PATH
    )
    mark_as_advanced(AAXSDK_LIB_DEBUG)

    message("${AAXSDK_HOME}/Libs/Release/libAAXLibrary_libcpp.a")
    find_library(AAXSDK_LIB_RELEASE
        NAMES 
            libAAXLibrary_libcpp.a
            AAXLibrary${AAXSDK_LIB_SUFFIX}.lib
        PATHS
            "${AAXSDK_HOME}/Libs/Release/"
        NO_DEFAULT_PATH
    )
    mark_as_advanced(AAXSDK_LIB_RELEASE)

    find_program(AAXSDK_CREATE_PACKAGE
    	 "${AAXSDK_HOME}/Utilities/CreatePackage.bat"
    )
    mark_as_advanced(AAXSDK_CREATE_PACKAGE)

	if(NOT TARGET AAXSDK::AAXSDK)
    	add_library(AAXSDK::AAXSDK INTERFACE IMPORTED)
    	set_target_properties(AAXSDK::AAXSDK PROPERTIES
        	INTERFACE_INCLUDE_DIRECTORIES "${AAXSDK_INCLUDE_DIRS}"
    	)

    	if(APPLE)
	    	set_target_properties(AAXSDK::AAXSDK PROPERTIES 
    			INTERFACE_LINK_LIBRARIES 
    			"$<IF:$<CONFIG:Debug>,${AAXSDK_LIB_DEBUG},${AAXSDK_LIB_RELEASE}>")
	    endif()

	    if(MSVC)
	    	# on windows juce uses pragma comment(lib) to link against the AAXSDK so we only need to provide the 
	    	# path to the AAXSDK libs directory
	    	set_target_properties(AAXSDK::AAXSDK PROPERTIES 
    			INTERFACE_COMPILE_DEFINITIONS
    				"JucePlugin_AAXLibs_path=\"${AAXSDK_HOME}/Libs/\""
    		)

	    	# # by default the AAXSDK uses the Dynamic Runtime DLL
    		# set_target_properties(AAXSDK::AAXSDK PROPERTIES
    		# 	INTERFACE_COMPILE_OPTIONS
    		# 	"$<IF:$<CONFIG:Debug>,/MDd,/MD>"
    		# )
	    endif()
	endif()
endif()
