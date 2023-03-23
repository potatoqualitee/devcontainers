#
# Module manifest for module 'azHelper'
# Just a sample, really
#
@{

    # Script module or binary module file associated with this manifest.
    RootModule             = 'azHelper.psm1'

    # Version number of this module.
    ModuleVersion          = '1.0'

    # ID used to uniquely identify this module
    GUID                   = '0348a47c-21bb-4379-8e71-17e9f3e55272'

    # Description of the functionality provided by this module
    Description            = "Internal commands available to all functions in the Azure Functions app"

    # Functions to export from this module
    FunctionsToExport      = @(
        'Invoke-TlsWebRequest'
    )
    
    # this should stay even if nothing is exported
    CmdletsToExport        = @()
    VariablesToExport      = ''
    AliasesToExport        = @()
}
