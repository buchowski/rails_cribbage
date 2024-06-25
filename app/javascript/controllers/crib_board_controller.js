import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    playerOneScore: Number,
    playerTwoScore: Number,
  }
  connect() {
    const playerOneId = `${this.playerOneScoreValue}_lane_one`;
    const playerTwoId = `${this.playerTwoScoreValue}_lane_two`;
    const playerOneEl = document.getElementById(playerOneId);
    const playerTwoEl = document.getElementById(playerTwoId);

    playerOneEl?.classList.add('selected');
    playerTwoEl?.classList.add('selected');
  }
}
