@{
    Rules        = @{
        PSAlignAssignmentStatement         = @{
            Enable         = $true
            CheckHashtable = $true
        }
        PSAvoidSemicolonsAsLineTerminators = @{
            Enable = $true
        }
        PSPlaceCloseBrace                  = @{
            Enable             = $true
            NewLineAfter       = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }
        PSPlaceOpenBrace                   = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }
        PSProvideCommentHelp               = @{
            Enable                  = $true
            ExportedOnly            = $false
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'begin'
        }
        PSUseConsistentIndentation         = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }
        PSUseConsistentWhitespace          = @{
            Enable                                  = $true
            CheckInnerBrace                         = $true
            CheckOpenBrace                          = $true
            CheckOpenParen                          = $true
            CheckOperator                           = $true
            CheckPipe                               = $true
            CheckPipeForRedundantWhitespace         = $true
            CheckSeparator                          = $true
            CheckParameter                          = $true
            IgnoreAssignmentOperatorInsideHashTable = $true
        }
    }
    ExcludeRules = @(
        'PSMissingModuleManifestField',                          # This rule is not applicable until the module is built.
        'PSUseToExportFieldsInManifest',
        'PSUseShouldProcessForStateChangingFunctions',           # Because this is an interactive text editor - confirmations would break user experience
        'PSUseOutputTypeCorrectly',                              # Because sometime we need to return predefined objects
        'AvoidLongLines',                                        # Because some lines are long for better readability in certain contexts
        'PSAvoidUsingWriteHost',                                 # Because this is an interactive editor with colored UI
        'PSReviewUnusedParameter',                               # Because some parameters are used in script blocks or passed to other functions
        'PSUseUsingScopeModifierInNewRunspaces',                 # Because we want to control the scope explicitly in runspaces
        'PSUseBOMForUnicodeEncodedFile',                         # Because we want to use UTF8 without BOM for better compatibility
        'PSAvoidUsingComputerNameHardcoded',                     # Because some functions require hardcoded computer names for remote operations
        'PSProvideCommentHelp'                                   # Because not all functions need comment-based help in this context
    )
}
