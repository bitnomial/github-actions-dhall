let haskellCi = ./haskell-ci.dhall

let concatMap =
      https://raw.githubusercontent.com/dhall-lang/dhall-lang/9f259cd68870b912fbf2f2a08cd63dc3ccba9dc3/Prelude/Text/concatMap sha256:7a0b0b99643de69d6f94ba49441cd0fa0507cbdfa8ace0295f16097af37e226f

let egiInstall =
      haskellCi.BuildStep.Name
        { name = "Install egison"
        , run =
            ''
            cabal update
            cabal install egison
            ''
        }

let checkEgi =
      λ(egis : List Text) →
        haskellCi.BuildStep.Name
          { name = "Check Egison files"
          , run =
                  ''
                  export PATH=$HOME/.cabal/bin:$PATH
                  ''
              ++  concatMap
                    Text
                    ( λ(d : Text) →
                        ''
                        egison --test ${d}
                        ''
                    )
                    egis
          }

let egiSteps =
      λ(steps : List haskellCi.BuildStep) →
            haskellCi.ciNoMatrix
              (   [ haskellCi.checkout
                  , haskellCi.haskellEnv haskellCi.latestEnv
                  , haskellCi.cache
                  , egiInstall
                  ]
                # steps
              )
          ⫽ { name = "Egison CI" }
        : haskellCi.CI.Type

let egiCi = λ(egis : List Text) → egiSteps [ checkEgi egis ] : haskellCi.CI.Type

in  { egiInstall
    , egiCi
    , checkEgi
    , egiSteps
    , CI = haskellCi.CI.Type
    , BuildStep = haskellCi.BuildStep
    , Event = haskellCi.Event
    }
