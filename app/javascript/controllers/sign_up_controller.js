
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["password", "confirmPassword"];

  validate(event) {
    event.preventDefault();

    const password = this.passwordTarget.value;
    const confirmPassword = this.confirmPasswordTarget.value;

    if (password !== confirmPassword) {
      // Display an error message or perform any other validation logic
      console.log("Password and confirm password do not match");
      return;
    }

    // Password and confirm password are valid, continue with form submission
    this.element.submit();
  }
}
