# Settings for PSScriptAnalyzer only applied to PSBite
@{
    ExcludeRules = @(
        'PSUseShouldProcessForStateChangingFunctions'           # Because this is an interactive text editor - confirmations would break user experience
        'PSUseOutputTypeCorrectly'                              # Because sometime we need to return predefined objects
        'AvoidLongLines'                                        # Because some lines are long for better readability in certain contexts
        'PSAvoidUsingWriteHost'                                 # Because this is an interactive editor with colored UI
        'PSReviewUnusedParameter'                               # Because some parameters are used in script blocks or passed to other functions
        'PSUseUsingScopeModifierInNewRunspaces'                 # Because we want to control the scope explicitly in runspaces
        'PSUseBOMForUnicodeEncodedFiles'                        # Because we want to use UTF8 without BOM for better compatibility
        'PSUseShouldProcessForStateChangingFunctions'           # Because this is an interactive text editor - confirmations would break user experience
    )
}