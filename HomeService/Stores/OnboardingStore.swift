import SwiftUI

@Observable
class OnboardingStore {
    var currentStep: Int = 1
    let totalSteps: Int = 12
    var responses = OnboardingResponses()
    var isComplete: Bool = false

    func nextStep() {
        saveResponses()
        if currentStep < totalSteps {
            withAnimation(HBAnimation.transition) {
                currentStep += 1
            }
        } else {
            withAnimation(HBAnimation.transition) {
                isComplete = true
            }
        }
    }

    func previousStep() {
        if currentStep > 1 {
            withAnimation(HBAnimation.transition) {
                currentStep -= 1
            }
        }
    }

    func complete() {
        saveResponses()
        withAnimation(HBAnimation.transition) {
            isComplete = true
        }
    }

    func saveResponses() {
        if let data = try? JSONEncoder().encode(responses) {
            UserDefaults.standard.set(data, forKey: "hb_onboarding_responses")
        }
    }

    static func loadResponses() -> OnboardingResponses? {
        guard let data = UserDefaults.standard.data(forKey: "hb_onboarding_responses") else { return nil }
        return try? JSONDecoder().decode(OnboardingResponses.self, from: data)
    }

    var canContinue: Bool {
        switch currentStep {
        case 1: return true
        case 2: return responses.homeType != nil
        case 3: return responses.homeAge != nil
        case 4: return responses.frequency != nil
        case 5: return !responses.selectedSystems.isEmpty
        case 6: return !responses.goals.isEmpty
        case 7: return responses.biggestChallenge != nil
        case 8: return true
        case 9: return responses.notificationPreference != nil
        case 10...12: return true
        default: return true
        }
    }
}
