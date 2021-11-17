pragma solidity ^0.8.7;

contract SimpleJKP {
    // Choices enum
    enum Choice {
        None,
        Rock,
        Paper,
        Scissors
    }
    
    // EndGame variations enum
    enum GameState {
        Win,
        Lose,
        Draw
    }
    
    // A matrix containing result of the game depedning on its states
    mapping(Choice => mapping(Choice => GameState)) private endgame_states;
    
    constructor() {
        endgame_states[Choice.Rock][Choice.Rock] = GameState.Draw;
        endgame_states[Choice.Rock][Choice.Paper] = GameState.Lose;
        endgame_states[Choice.Rock][Choice.Scissors] = GameState.Win;
        endgame_states[Choice.Paper][Choice.Rock] = GameState.Win;
        endgame_states[Choice.Paper][Choice.Paper] = GameState.Draw;
        endgame_states[Choice.Paper][Choice.Scissors] = GameState.Lose;
        endgame_states[Choice.Scissors][Choice.Rock] = GameState.Lose;
        endgame_states[Choice.Scissors][Choice.Paper] = GameState.Win;
        endgame_states[Choice.Scissors][Choice.Scissors] = GameState.Draw;
    }
    
    // contains commitments [_player][_other_player]
    mapping (address => mapping (address => bytes32)) choise_hashes;
    // contains states of choises choise[_player][_other_player]
    mapping (address => mapping (address => Choice)) choises;
    // contains "ready to reset game" flag for _player][_other_player] (both must accept game reset)
    mapping (address => mapping (address => bool)) ready_for_reset;
    
    function reset_game(address _other_player_address) public returns (bool success) {
        require(ready_for_reset[msg.sender][_other_player_address] && ready_for_reset[_other_player_address][msg.sender], "One of the opponents haven't finish current game (check result). Finish current game first!");
        ready_for_reset[msg.sender][_other_player_address] = false;
        ready_for_reset[_other_player_address][msg.sender] = false;
        choise_hashes[msg.sender][_other_player_address] = 0;
        choise_hashes[_other_player_address][msg.sender] = 0;
        choises[msg.sender][_other_player_address] = Choice.None;
        choises[_other_player_address][msg.sender] = Choice.None;
        return true;
    }
    
    function commit_choise(address _other_player_address, bytes32 commitment) public returns (bool success) {
        require(choise_hashes[msg.sender][_other_player_address] == 0, "Choise is already commited!");
        choise_hashes[msg.sender][_other_player_address] = commitment;
        return true;
    }
    
    function reval_choise(address _other_player_address, Choice choice, bytes32 nonce) public returns (bool success) {
        require(choise_hashes[msg.sender][_other_player_address] != 0, "Your choise should be commited!");
        require(choise_hashes[_other_player_address][msg.sender] != 0, "Your opponent's choise should be commited!");
        require(choises[msg.sender][_other_player_address] == Choice.None, "Already revaled!");
         // Check the hash to ensure the commitment is correct
        require(keccak256(abi.encodePacked(choice, nonce)) == choise_hashes[msg.sender][_other_player_address], "Can't accept choise: invalid hash");
        choises[msg.sender][_other_player_address] = choice;
        return true;
    }
    
    function get_result(address _other_player_address) public returns (uint8 result) {
        require(choises[msg.sender][_other_player_address] != Choice.None, "You have to reval your choise first!");
        require(choises[_other_player_address][msg.sender] != Choice.None, "Your opponent have to reval his choise first!");
        GameState game_result = endgame_states[choises[msg.sender][_other_player_address]][choises[_other_player_address][msg.sender]];
        ready_for_reset[msg.sender][_other_player_address] = true;
        emit EndGame(msg.sender, _other_player_address, uint8(game_result));
        return uint8(game_result);
    }
    
    event EndGame(address indexed _from, address indexed _to, uint8 _result);
}
