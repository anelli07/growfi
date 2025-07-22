import Foundation
import GoogleSignIn
import GoogleSignInSwift

class ApiService {
    static let shared = ApiService()
//    private let baseURL = "http://127.0.0.1:8000/api/v1"
    private let baseURL = "https://growfi-backend.azurewebsites.net/api/v1"
    private init() {}

    // MARK: - Авторизация
    func login(email: String, password: String, completion: @escaping (Result<(String, String), Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyString = "username=\(email)&password=\(password)"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NSError(domain: "Проблемы с сетью", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Нет данных от сервера", code: 0)));
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let access = json["access_token"] as? String,
               let refresh = json["refresh_token"] as? String {
                completion(.success((access, refresh)))
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let detail = json["detail"] as? String {
                completion(.failure(NSError(domain: "Ошибка", code: 0, userInfo: [NSLocalizedDescriptionKey: detail])))
            } else {
                completion(.failure(NSError(domain: "Неверный ответ сервера", code: 0)))
            }
        }.resume()
    }

    // MARK: - Refresh token
    func refreshToken(refreshToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/refresh") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["refresh_token": refreshToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let access = json["access_token"] as? String {
                completion(.success(access))
            } else {
                completion(.failure(NSError(domain: "Invalid response", code: 0)))
            }
        }.resume()
    }

    // MARK: - Logout
    func logout(refreshToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/logout") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["refresh_token": refreshToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }

    // MARK: - Получение транзакций
    func fetchTransactions(token: String, completion: @escaping (Result<[Transaction], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/transactions") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)));
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let transactions = try decoder.decode([Transaction].self, from: data)
                completion(.success(transactions))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Регистрация
    func register(email: String, password: String, fullName: String? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["email": email, "password": password]
        if let fullName = fullName { body["full_name"] = fullName }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NSError(domain: "Проблемы с сетью", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Нет данных от сервера", code: 0)));
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let detail = json["detail"] as? String {
                completion(.failure(NSError(domain: "Ошибка", code: 0, userInfo: [NSLocalizedDescriptionKey: detail])))
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let message = json["message"] as? String {
                completion(.failure(NSError(domain: "Ошибка", code: 0, userInfo: [NSLocalizedDescriptionKey: message])))
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Ошибка регистрации", code: httpResponse.statusCode)))
            } else {
                completion(.success(()))
            }
        }.resume()
    }

    // MARK: - Восстановление пароля (запрос на email)
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/reset-password-request") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NSError(domain: "Проблемы с сетью", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Нет данных от сервера", code: 0)));
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let detail = json["detail"] as? String {
                completion(.failure(NSError(domain: "Ошибка", code: 0, userInfo: [NSLocalizedDescriptionKey: detail])))
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Ошибка восстановления пароля", code: httpResponse.statusCode)))
            } else {
                completion(.success(()))
            }
        }.resume()
    }

    // MARK: - Подтверждение сброса пароля (установка нового пароля)
    func confirmResetPassword(token: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/reset-password") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["token": token, "new_password": newPassword]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NSError(domain: "Проблемы с сетью", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Нет данных от сервера", code: 0)));
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let detail = json["detail"] as? String {
                completion(.failure(NSError(domain: "Ошибка", code: 0, userInfo: [NSLocalizedDescriptionKey: detail])))
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Ошибка сброса пароля", code: httpResponse.statusCode)))
            } else {
                completion(.success(()))
            }
        }.resume()
    }

    // MARK: - Google Auth (заглушка)
    func loginWithGoogle(presentingViewController: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let idToken = result?.user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "Нет idToken", code: 0)))
                return
            }
            // Отправляем idToken на бэкенд
            guard let url = URL(string: "\(self.baseURL)/auth/google") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = ["token": idToken]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let token = json["access_token"] as? String {
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "Invalid response", code: 0)))
                }
            }.resume()
        }
    }

    func loginWithApple(idToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("[ApiService] loginWithApple called, idToken: \(idToken.prefix(40))...")
        guard let url = URL(string: "\(baseURL)/auth/apple") else { print("[ApiService] Invalid URL"); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["token": idToken]
        print("[ApiService] loginWithApple body: \(body)")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { print("[ApiService] error: \(error)"); completion(.failure(error)); return }
            guard let data = data else { print("[ApiService] no data"); completion(.failure(NSError(domain: "No data", code: 0))); return }
            print("[ApiService] got data, response: \(String(data: data, encoding: .utf8) ?? "nil")")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let token = json["access_token"] as? String {
                print("[ApiService] access_token: \(token.prefix(20))...")
                completion(.success(token))
            } else {
                print("[ApiService] Invalid response")
                completion(.failure(NSError(domain: "Invalid response", code: 0)))
            }
        }.resume()
    }

    // MARK: - Получение доходов
    func fetchIncomes(token: String, completion: @escaping (Result<[Income], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/incomes/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)));
                return
            }
            do {
                let decoder = JSONDecoder()
                let paged = try decoder.decode(PaginatedResponse<Income>.self, from: data)
                completion(.success(paged.items))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Получение расходов
    func fetchExpenses(token: String, completion: @escaping (Result<[Expense], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/expenses/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)));
                return
            }
            do {
                let decoder = JSONDecoder()
                let paged = try decoder.decode(PaginatedResponse<Expense>.self, from: data)
                completion(.success(paged.items))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Подтверждение email
    func verifyCode(email: String, code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/verify-code") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email, "code": code]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(NSError(domain: "Проблемы с сетью", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))); return }
            guard let data = data else { completion(.failure(NSError(domain: "Нет данных от сервера", code: 0))); return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let detail = json["detail"] as? String {
                completion(.failure(NSError(domain: "Ошибка", code: 0, userInfo: [NSLocalizedDescriptionKey: detail])))
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Ошибка подтверждения email", code: httpResponse.statusCode)))
            } else {
                completion(.success(()))
            }
        }.resume()
    }

    // MARK: - Повторная отправка кода
    func resendCode(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/resend-code") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }

    // MARK: - Цели
    func fetchGoals(token: String, completion: @escaping (Result<[Goal], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/goals/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let goals = try JSONDecoder().decode([Goal].self, from: data)
                completion(.success(goals))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func createGoal(name: String, targetAmount: Double, currentAmount: Double, currency: String, icon: String, color: String, reminderPeriod: String? = nil, selectedWeekday: Int? = nil, selectedMonthDay: Int? = nil, selectedTime: String? = nil, token: String, completion: @escaping (Result<Goal, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/goals/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any?] = [
            "name": name,
            "target_amount": targetAmount,
            "current_amount": currentAmount,
            "currency": currency,
            "icon": icon,
            "color": color,
            "reminder_period": reminderPeriod,
            "selected_weekday": selectedWeekday,
            "selected_month_day": selectedMonthDay,
            "selected_time": selectedTime
        ]
        print("createGoal body:", body)
        request.httpBody = try? JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let goal = try JSONDecoder().decode(Goal.self, from: data)
                completion(.success(goal))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func updateGoal(goal: Goal, icon: String, color: String, token: String, completion: @escaping (Result<Goal, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/goals/\(goal.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any?] = [
            "name": goal.name,
            "target_amount": goal.target_amount,
            "icon": icon,
            "color": color,
            "current_amount": goal.current_amount,
            "reminder_period": goal.reminderPeriod,
            "selected_weekday": goal.selectedWeekday,
            "selected_month_day": goal.selectedMonthDay,
            "selected_time": goal.selectedTime
        ]
        print("updateGoal body:", body)
        request.httpBody = try? JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let goal = try JSONDecoder().decode(Goal.self, from: data)
                completion(.success(goal))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func deleteGoal(goalId: Int, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/goals/\(goalId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }

    // MARK: - Кошельки
    func fetchWallets(token: String, completion: @escaping (Result<[Wallet], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/wallet/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let wallets = try JSONDecoder().decode([Wallet].self, from: data)
                completion(.success(wallets))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func createWallet(name: String, balance: Double, currency: String, icon: String, color: String, token: String, completion: @escaping (Result<Wallet, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/wallet/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "name": name,
            "balance": balance,
            "currency": currency,
            "icon_name": icon,
            "color_hex": color
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let wallet = try JSONDecoder().decode(Wallet.self, from: data)
                completion(.success(wallet))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func updateWallet(id: Int, name: String, balance: Double, icon: String, color: String, token: String, completion: @escaping (Result<Wallet, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/wallet/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "name": name,
            "balance": balance,
            "icon_name": icon,
            "color_hex": color
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let wallet = try JSONDecoder().decode(Wallet.self, from: data)
                completion(.success(wallet))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func deleteWallet(walletId: Int, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/wallet/\(walletId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }

    // MARK: - Доходы
    func createIncome(name: String, icon: String, color: String, categoryId: Int?, token: String, completion: @escaping (Result<Income, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/incomes/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "name": name,
            "icon": icon,
            "color": color
        ]
        if let categoryId = categoryId { body["category_id"] = categoryId }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let income = try JSONDecoder().decode(Income.self, from: data)
                completion(.success(income))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func updateIncome(id: Int, name: String, icon: String, color: String, description: String?, token: String, completion: @escaping (Result<Income, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/incomes/\(id)/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "name": name,
            "icon": icon,
            "color": color,
            "description": description ?? ""
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let income = try JSONDecoder().decode(Income.self, from: data)
                completion(.success(income))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Если assignIncomeToWallet по бизнес-логике реально возвращает Transaction (создаёт движение), оставляем Transaction. Если нужен Income — поменяй на Income.
    func assignIncomeToWallet(incomeId: Int, walletId: Int, amount: Double, date: String, comment: String?, categoryId: Int?, token: String, completion: @escaping (Result<AssignIncomeResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/incomes/\(incomeId)/assign") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "wallet_id": walletId,
            "amount": amount,
            "date": date
        ]
        if let comment = comment { body["comment"] = comment }
        if let categoryId = categoryId { body["category_id"] = categoryId }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let resp = try JSONDecoder().decode(AssignIncomeResponse.self, from: data)
                completion(.success(resp))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func deleteIncome(incomeId: Int, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/incomes/\(incomeId)") else { return } // убрал слэш
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }


            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }

    // MARK: - Расходы
    func createExpense(name: String, icon: String, color: String, categoryId: Int?, walletId: Int?, token: String, completion: @escaping (Result<Expense, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/expenses/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "name": name,
            "icon": icon,
            "color": color
        ]
        if let categoryId = categoryId { body["category_id"] = categoryId }
        if let walletId = walletId { body["wallet_id"] = walletId }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let expense = try JSONDecoder().decode(Expense.self, from: data)
                completion(.success(expense))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func updateExpense(id: Int, name: String, icon: String, color: String, description: String?, token: String, completion: @escaping (Result<Expense, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/expenses/\(id)/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "name": name,
            "icon": icon,
            "color": color,
            "description": description ?? ""
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let expense = try JSONDecoder().decode(Expense.self, from: data)
                completion(.success(expense))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func deleteExpense(expenseId: Int, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/expenses/\(expenseId)") else { return } // убрал слэш
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }


            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }

    // MARK: - Кошельки
    func assignWalletToGoal(walletId: Int, goalId: Int, amount: Double, date: String, comment: String?, token: String, completion: @escaping (Result<AssignGoalResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/wallet/\(walletId)/assign-goal") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "goal_id": goalId,
            "amount": amount,
            "date": date
        ]
        if let comment = comment { body["comment"] = comment }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let resp = try JSONDecoder().decode(AssignGoalResponse.self, from: data)
                completion(.success(resp))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func assignWalletToExpense(walletId: Int, expenseId: Int, amount: Double, date: String, comment: String?, token: String, completion: @escaping (Result<AssignExpenseResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/wallet/\(walletId)/assign-expense") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "expense_id": expenseId,
            "amount": amount,
            "date": date
        ]
        if let comment = comment { body["comment"] = comment }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let resp = try JSONDecoder().decode(AssignExpenseResponse.self, from: data)
                completion(.success(resp))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchCurrentUser(token: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/me") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404,
            let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let detail = json["detail"] as? String, detail == "User not found" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
            }
            completion(.failure(NSError(domain: "UserNotFound", code: 404)))
            return
        }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                // Разлогиниваем пользователя
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Категории
    func fetchCategories(token: String, completion: @escaping (Result<[Category], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/categories/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let categories = try JSONDecoder().decode([Category].self, from: data)
                completion(.success(categories))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Удаление аккаунта
    func deleteAccount(token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/me") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutDueTo401"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401)))
                return
            }
            
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }
} 
 
struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    // Можно добавить total, page, size, pages если нужно
} 
 
struct AssignExpenseResponse: Codable {
    let expense: Expense
    let wallet: Wallet
}

struct AssignGoalResponse: Codable {
    let goal: Goal
    let wallet: Wallet
}

struct AssignIncomeResponse: Codable {
    let income: Income
    let wallet: Wallet
} 
 
