Shortening codes is a key feature that aids their usability.

Being able to say _WF8Q+WF, Praia_ is significantly easier than remembering and using _796RWF8Q+WF_. With that in mind, how do you choose the locality to use as a reference?

Ideally, you need to use both the center point and the bounding box.

Given a global code, _796RWF8Q+WF_, you can eliminate the first **four** digits of the code if:
 * The center point of the feature is within **0.4** degrees latitude and **0.4** degrees longitude
 * The bounding box of the feature is less than **0.8** degrees high and wide.

If there is no suitable locality close enough or small enough, you can eliminate the first **two** digits of the code if:
 * The center point of the feature is within **8** degrees latitude and **8** degrees longitude
 * The bounding box of the feature is less than **16** degrees high and wide.

These values are are chosen to allow for different geocoder backends placing localities in slightly different positions. Although they can be slightly increased there will be a risk that a shortened code will recover to a different location than the original, and people misdirected.

Note: Usually your feature will be a town or city, but you could also use geographical features such as lakes or mountains, if they are the best local reference. If a settlement (such as neighbourhood, town or city) is to be used, you should choose the most prominent feature that meets the requirements, to avoid using obscure features that may not be widely known.