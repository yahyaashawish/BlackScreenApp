

import SwiftUI


enum ExtractedVideoAlert : Equatable{
        case videoSaved
        case videoSavingError
        case videoTitleEmpty
        case videoExtractingError
        case videosFetchingError
        case videoDeletingError
        case none
        var title: LocalizedStringKey {
            switch self {
            
            case .none:
                ""
            case .videoSaved:
                "Video Saved!"
            case .videoSavingError:
                "Something went wrong!"
            
            case .videoTitleEmpty:
                "Empty title!"
            case .videoExtractingError:
                "Something went wrong!"
            case .videosFetchingError:
                "Something went wrong!"

            case .videoDeletingError:
                "Something went wrong!"

            }
        }
    
        var message: LocalizedStringKey {
                switch self {

                case .none:
                    ""
                case .videoSaved:
                    "Video saved successfully to app library."
                    
                case .videoSavingError:
                    "Something went wrong while saving the video,try again."
                case .videoTitleEmpty:
                    "please enter a valid title!"
                case .videoExtractingError:
                    "Something went wrong while extracting the video,try again."
                case .videosFetchingError:
                    "Something went wrong while fetching the videos,try again!"

                case .videoDeletingError:
                    "Something went wrong while deleting the video,try again!"

                }
            
 
        }
}
