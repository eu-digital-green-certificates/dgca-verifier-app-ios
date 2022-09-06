# Usage Verifier + Wallet App (iOS)

## Packages
Both apps need several [packages](https://github.com/eu-digital-green-certificates/dgca-verifier-app-ios#documentation) to run properly. Those are already present in the application and need to be up-to-date in order for the app to run. 

### Updating the app's packages
In XCode run 
> File > Packages > Update to Latest Package Versions 

If you encounter errors upon building the project, run 
> File > Packages > Reset Package Caches 

and 
> Product > Clean Build Folder.

## Changing the apps configuration
The apps can be configured to talk to endpoints sepearetely defined in a file called _context.json_. This file can be found in the file explorer under:
> dgca-verifier-app-ios > context > Release/Test > _context.json_

_Release_ is the context file used when building for production.

_Test_ is the context file used when building for testing.

## Signing the application
Please use your own enterprise Apple Developer Account for signing.

## Where do I find the latest version?
#### Verifier App:
>       Branch: feature/multy-type-certificate
>       Commit: ffec1 
#### Wallet App:
>       Branch: feat/smart-health-cards
>       Commit: d6d9e8
