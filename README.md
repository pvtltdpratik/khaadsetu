### KHAAD Setu

Cross platform app built with Flutter for Indian farmers, mainly targeting small and marginal farmers doing organic farming or shifting towards it. This was my attempt at solving a real problem instead of building another todo app for my resume lol.

The idea is simple - most farmers don't have proper access to soil testing or correct fertilizer info, and a lot of decisions are still made on guesswork or whatever the local shopkeeper tells them. So this app tries to bring some actual data into that process.

### What it does

- Farmer can scan soil using phone camera and get a rough health estimate (still improving accuracy on this, ML model needs more training data)
- Suggests fertilizers based on soil result + past crop history instead of just showing random products
- Has a village center side too - basically an app for the local shop owner who helps farmers who aren't comfortable with tech
- Pulls weather info and mandi prices so farmer doesn't need to switch apps
- Govt scheme matching (PM-KISAN, PKVY etc) based on farmer's land and crop details
- Works offline for the village center part since network in rural areas is not great, syncs later when connection is back

### Tech stack

Flutter + Dart for app, following clean architecture (domain/data/presentation split) with Riverpod for state mgmt. Using Isar for local storage since app needs to work without internet most of the time. Backend not included in this repo yet, will push separately once it's more stable.

### Status

Still very much a work in progress, built this mostly during sem breaks and free time. UI is not final in many screens, some features are just usecases right now without proper UI hooked up. ML model accuracy needs a lot more soil samples before it's actually reliable for real farmers.

Open to suggestions if anyone's worked on agri-tech stuff before, would genuinely love to learn from that.

---

Want me to also give you a matching commit message style or a basic README.md file to go along with this repo description?
