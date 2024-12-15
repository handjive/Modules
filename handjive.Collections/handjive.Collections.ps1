using module handjive.ValueHolder
using module handjive.ChainScript

using namespace handjive.Collections

. "$PSScriptRoot\PluggableEnumerator.ps1"
. "$PSScriptRoot\CombinedComparer.ps1"
. "$PSScriptRoot\IndexAdaptor.ps1"
. "$PSScriptRoot\EnumerableWrapper.ps1"
#. "$PSScriptRoot\CollectionAdaptor.ps1"
. "$PSScriptRoot\Interval.ps1"
. "$PSScriptRoot\Bag.ps1"
. "$PSScriptRoot\ConvertingFactory.ps1"
. "$PSScriptRoot\EnumerableSorter.ps1"

[BagToEnumerableQuoter]::GetInstaller().InstallOn([Bag])
[BagToBagQuoter]::GetInstaller().InstallOn([Bag])
[BagToSetQuoter]::GetInstaller().InstallOn([Bag])
[BagToListQuoter]::GetInstaller().InstallOn([Bag])
[BagToEnumerableExtractor]::GetInstaller().InstallOn([Bag])
[BagToBagExtractor]::GetInstaller().InstallOn([Bag])
[BagToSetExtractor]::GetInstaller().InstallOn([Bag])
[BagToListExtractor]::GetInstaller().InstallOn([Bag])
