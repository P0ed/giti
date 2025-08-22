import Foundation

extension UserDefaults {

	var messageFormat: String {
		get { string(forKey: "messageFormat") ?? "#MSG" }
		set { set(newValue.contains("#MSG") ? newValue : nil, forKey: "messageFormat") }
	}
}
