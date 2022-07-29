//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.7;

import "./utils/Counters.sol";
import "./utils/String.sol";
import "./token/IERC20.sol";
import "./RandomNumberConsumer.sol";

contract Bingo {

    IERC20 public USD;

    RandomNumberConsumer public Ramdom;

    using Counters for Counters.Counter;

    enum statePlay {
        CREATED,
        INITIATED,
        FINALIZED
    }

    enum words {
        B,
        I,
        N,
        G,
        O
    }

    struct playDetail {
        uint256 idPlay;
        uint256 maxNumberCartons;
        uint256 cartonsSold;
        uint256 numberPlayer;
        uint256 cartonsByPlayer;
        uint256 cartonPrice;
        uint256 startPlayDate;
        uint256 endPlayDate;
        uint256 amountUSDT;
        uint256[] totalNumbers;
        uint256[] numbersPlayed;
        address ownerPlay;
        statePlay state;
    }

    struct cartonsDetail {
        uint256 idCarton;
        uint256 idPlay;
        mapping(words => uint256[]) number;
        address userOwner;
    }

    Counters.Counter private currentIdPlay;

    Counters.Counter private currentIdCartons;

    mapping(uint256 => playDetail) private play;

    mapping(uint256 => uint256[]) private PlayCartons;

    mapping(address => uint256[]) private userOwnerPlay;

    mapping(uint256 => cartonsDetail) private cartons;

    mapping(address => uint256[]) private userCartons;

    mapping(address => bool) private owner;

    //numeros posibles del bingo
    uint256[] private numbersOfBingo;
    mapping(words => uint256[]) private numbersOfBingoByWord;

    //events
    event CreateNewPlay(address owner, uint256 idPlay, uint256 date);

    event GenerateWinningNumbers(
        uint256 idPlay,
        uint256 winningNumbers,
        uint256 date
    );

    event ClaimPrize(
        uint256 idPlay,
        uint idCarton,
        address winer,
        uint256 date
    );

    event ChangeStatePlayToInitiated(
        uint256 idPlay,
        address owner,
        uint256 date
    );

    event BuyCartonsPlay(
        uint256 idPlay,
        uint256 idCarton,
        address owner,
        uint256 date
    );

    //modifier
    modifier onlyOwner() {
        require(owner[msg.sender] == true, "Exclusive function of the Owner");
        _;
    }

    function isOwner(address _account) external view returns (bool) {
        return owner[_account];
    }

    function getCurrentIdPLay() external view returns (uint256) {
        return currentIdPlay.current();
    }

    function getCurrentIdCartons() external view returns (uint256) {
        return currentIdCartons.current();
    }

    function getCartonsByUser(address _user)
    external
    view 
    returns( uint256[] memory){
        return userCartons[_user];
    }

    function getPlayDetail(uint256 _idPlay)
        external
        view
        returns (playDetail memory)
    {
        return play[_idPlay];
    }

    function getRamdonNumber() external view returns (uint256) {
        return Ramdom.s_requestId();
    }

    function createAllNumberOfBingo() private onlyOwner returns (bool) {
        for (uint256 i = 1; i <= 75; i++) {
         
            numbersOfBingo.push(i);

            //Numeros por letra
            if (i >= 0 && i <= 15) {
                numbersOfBingoByWord[words.B].push(i);
            }
            if (i >= 16 && i <= 30) {
                numbersOfBingoByWord[words.I].push(i);
            }
            if (i >= 31 && i <= 45) {
                numbersOfBingoByWord[words.N].push(i);
            }
            if (i >= 46 && i <= 60) {
                numbersOfBingoByWord[words.G].push(i);
            }
            if (i >= 61 && i <= 75) {
                numbersOfBingoByWord[words.O].push(i);
            }
        }

        return true;
    }

    // function getNumberOfWord() external view returns (uint256[] memory) {
    //     return numbersOfBingo;
    // }

    function getIdCartonsPlay(uint256 _idPlay)
        external
        view
        returns (uint256[] memory)
    {
        return PlayCartons[_idPlay];
    }

    function getNumberCartonsByWord(uint256 _idCartons, words _word)
        internal
        view
        returns (uint256[] memory)
    {
        return cartons[_idCartons].number[_word];
    }

    function getAllNumersCartons(uint256 _idCarton)
        public
        view
        returns (uint256[25] memory)
    {
        require(cartons[_idCarton].idCarton > 0, "the carton no existe");

        uint256[25] memory totalNumber;

        uint256[] memory arrayWordB = getNumberCartonsByWord(
            _idCarton,
            words.B
        );
        uint256[] memory arrayWordI = getNumberCartonsByWord(
            _idCarton,
            words.I
        );
        uint256[] memory arrayWordN = getNumberCartonsByWord(
            _idCarton,
            words.N
        );
        uint256[] memory arrayWordG = getNumberCartonsByWord(
            _idCarton,
            words.G
        );
        uint256[] memory arrayWordO = getNumberCartonsByWord(
            _idCarton,
            words.O
        );

        for (uint256 i = 0; i < 25; i++) {
            if (i >= 0 && i < 5) {
                totalNumber[i] = arrayWordB[i];
            }
            if (i >= 5 && i < 10) {
                totalNumber[i] = arrayWordI[i - 5];
            }
            if (i >= 10 && i < 15) {
                totalNumber[i] = arrayWordN[i - 10];
            }
            if (i >= 15 && i < 20) {
                totalNumber[i] = arrayWordG[i - 15];
            }
            if (i >= 20 && i < 25) {
                totalNumber[i] = arrayWordO[i - 20];
            }
        }

        return totalNumber;
    }

    function getNumbersPlayedByPlay(uint256 _idPlay)
        public
        view
        returns (uint256[] memory)
    {
        return play[_idPlay].numbersPlayed;
    }

    function isUserOwnerPlay(address _account, uint256 _idPlay)
        internal
        view
        returns (bool)
    {
        bool playReturn = false;
        if (userOwnerPlay[_account].length > 0) {
            for (uint256 i = 0; i < userOwnerPlay[_account].length; i++) {
                if (userOwnerPlay[_account][i] == _idPlay) {
                    playReturn = true;
                }
            }
        }
        return playReturn;
    }

    function changeStatePlayToInitiated(uint256 _idPlay)
        external
        returns (bool)
    {
        require(isUserOwnerPlay(msg.sender, _idPlay), "you don't own the game");

        require(
            play[_idPlay].endPlayDate > block.timestamp,
            "the end date of has already happened"
        );

        play[_idPlay].state = statePlay.INITIATED;

        return true;
    }

    function changeStatePlayToFinalied(uint256 _idPlay)
        external
        returns (bool)
    {
        require(isUserOwnerPlay(msg.sender, _idPlay), "you don't own the game");

        require(
            play[_idPlay].endPlayDate > block.timestamp,
            "the end date of has already happened"
        );

        play[_idPlay].state = statePlay.FINALIZED;

        emit ChangeStatePlayToInitiated(_idPlay, msg.sender, block.timestamp);

        return true;
    }

    function isPlay(uint256 _idPlay) internal view returns (bool) {
        bool exists = false;

        if (_idPlay > 0 && play[_idPlay].idPlay == _idPlay) {
            exists = true;
        }
        return exists;
    }

    function isCartonPlay(uint256 _idPlay, uint256 _idCarton)
        internal
        view
        returns (bool)
    {
        bool exists = false;

        if (PlayCartons[_idPlay].length > 0) {
            for (uint256 i = 0; i < PlayCartons[_idPlay].length; i++) {
                if (PlayCartons[_idPlay][i] == _idCarton) {
                    exists = true;
                }
            }
        }

        return exists;
    }

    function getPlayOwnerUser(address _user) external view returns (uint256[] memory) {
        return userOwnerPlay[_user];
    }

    function createPlay(
        uint256 _maxNumberCartons,
        uint256 _numberPlayer,
        uint256 _cartonsByPlayer,
        uint256 _cartonPrice,
        uint256 _endDate
    ) external returns (bool) {
        require(
            block.timestamp < _endDate,
            "The game end date must be greater than the current date"
        );

        require(
            _cartonPrice > 0,
            "The price of the carton must be greater than zero"
        );

        uint256 _idPlay = currentIdPlay.current();

        play[_idPlay].idPlay = _idPlay;
        play[_idPlay].maxNumberCartons = _maxNumberCartons;
        play[_idPlay].numberPlayer = _numberPlayer;
        play[_idPlay].cartonsByPlayer = _cartonsByPlayer;
        play[_idPlay].cartonPrice = _cartonPrice;
        play[_idPlay].startPlayDate = block.timestamp;
        play[_idPlay].endPlayDate = _endDate;
        play[_idPlay].state = statePlay.CREATED;
        play[_idPlay].ownerPlay = msg.sender;
        play[_idPlay].amountUSDT = 0;
        play[_idPlay].cartonsSold = 0;

        play[_idPlay].totalNumbers = numbersOfBingo;

        userOwnerPlay[msg.sender].push(_idPlay);

        currentIdPlay.increment();

        emit CreateNewPlay(msg.sender, _idPlay, block.timestamp);

        return true;
    }

    function removeIndexArray(uint256[] memory array, uint256 index)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory arrayNew = new uint256[](array.length - 1);
        for (uint256 i = 0; i < arrayNew.length; i++) {
            if (i != index && i < index) {
                arrayNew[i] = array[i];
            } else {
                arrayNew[i] = array[i + 1];
            }
        }
        return arrayNew;
    }

    function generateNumberRamdom(
        uint256 _idPlayOrCarton,
        uint256 _min,
        uint256 _max,
        uint256 _seed
    ) internal view returns (uint256) {
        require(_seed != 0, "seed cannot be 0");

        uint256 _seedTemp = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, _idPlayOrCarton, _seed)
            )
        ) % _max;

        _seedTemp = _seedTemp + _min;

        return (_seedTemp);
    }

    function _buyCartonsPlay(
        uint256 _idPlay,
        uint256 _cartonsNumber,
        address _user
    ) internal returns (bool) {
        //llamar para generar nueva cemilla
        Ramdom.requestRandomWords();

        uint256 _seed = Ramdom.s_requestId();

        require(_seed != 0, "seed cannot be 0");

        uint256 valueCartonsBuy = play[_idPlay].cartonPrice * _cartonsNumber;

        USD.approve(address(this), valueCartonsBuy);

        USD.transferFrom(_user, address(this), valueCartonsBuy);

        play[_idPlay].amountUSDT += valueCartonsBuy;

        for (uint256 i = 0; i < _cartonsNumber; i++) {
            
            uint256 idCarton = currentIdCartons.current();

            PlayCartons[_idPlay].push(idCarton);
            userCartons[_user].push(idCarton);
            cartons[idCarton].userOwner = _user;

            play[_idPlay].cartonsSold++;
            cartons[idCarton].idCarton = idCarton;
            cartons[idCarton].idPlay = _idPlay;

            //COLUMNAS
            // j = 0 --> B
            // j = 1 --> I
            // j = 2 --> N
            // j = 3 --> G
            // j = 4 --> O
            for (uint256 j = 0; j < 5; j++) {
                uint256 min;
                uint256 max;
                words wordCarton;

                //index Words B
                if (j == 0) {
                    min = 1;
                    max = 15;
                    wordCarton = words.B;
                }

                //index Words I
                if (j == 1) {
                    min = 16;
                    max = 30;
                    wordCarton = words.I;
                }

                //index Words N
                if (j == 2) {
                    min = 31;
                    max = 45;
                    wordCarton = words.N;
                }

                //index Words G
                if (j == 3) {
                    min = 46;
                    max = 60;
                    wordCarton = words.G;
                }

                //index Words O
                if (j == 4) {
                    min = 61;
                    max = 75;
                    wordCarton = words.O;
                }

                uint256[] memory possibleNumber = numbersOfBingoByWord[
                    wordCarton
                ];

                //FILAS
                //sacar a una funcion?
                for (uint256 x = 0; x < 5; x++) {
                    uint256 ramdonIndex = generateNumberRamdom(
                        i, //
                        0, // min
                        possibleNumber.length, // max
                        _seed
                    );

                    cartons[idCarton].number[wordCarton].push(
                        possibleNumber[ramdonIndex]
                    );

                    possibleNumber = removeIndexArray(
                        possibleNumber,
                        ramdonIndex
                    );
                }
            }

            emit BuyCartonsPlay(_idPlay, idCarton, _user, block.timestamp);

            currentIdCartons.increment();
        }

        return true;
    }

    function buyCartonsPlay(
        uint256 _idPlay,
        uint256 _cartonsToBuy
    ) external returns (bool) {

        
        uint256 _amount = play[_idPlay].cartonPrice * _cartonsToBuy;         

        require(
            isPlay(_idPlay) && play[_idPlay].state == statePlay.CREATED,
            "the id play not exists"
        );

        require(
            play[_idPlay].endPlayDate > block.timestamp,
            "the endgame date has already happened"
        );

        require(
            _cartonsToBuy > 0,
            "the number of cards to buy must be greater than 0"
        );

        require(
            USD.balanceOf(msg.sender) >= _amount,
            "Do not have the necessary funds of USD"
        );

        // require(
        //     _amount >= play[_idPlay].cartonPrice * _cartonsToBuy,
        //     "you do not send the amount of USDT necessary to make the purchase"
        // );

        require(
            play[_idPlay].cartonsByPlayer >= _cartonsToBuy,
            "can not buy that quantity of cartons"
        );

        require(
            play[_idPlay].maxNumberCartons > play[_idPlay].cartonsSold,
            "there are no cards to buy"
        );

        bool isBuyCartons = _buyCartonsPlay(
            _idPlay,
            _cartonsToBuy,
            msg.sender
        );

        return isBuyCartons;
    }

    function _generateWinningNumbers(uint256 _idPlay, uint256 _seed)
        internal
        returns (uint256)
    {
        uint256 randomIndex = generateNumberRamdom(
            _idPlay,
            0,
            play[_idPlay].totalNumbers.length,
            _seed
        );

        uint256 numberRamdon = play[_idPlay].totalNumbers[randomIndex];

        play[_idPlay].numbersPlayed.push(numberRamdon);

        play[_idPlay].totalNumbers = removeIndexArray(
            play[_idPlay].totalNumbers,
            randomIndex
        );

        return numberRamdon;
    }

    function generateWinningNumbers(uint256 _idPlay) external returns (bool) {
        require(isPlay(_idPlay), "the number is not a play");

        require(isUserOwnerPlay(msg.sender, _idPlay), "you don't own the game");

        require(
            play[_idPlay].state == statePlay.INITIATED,
            "the play is not INITIATED"
        );

        require(
            play[_idPlay].numbersPlayed.length != 75,
            "All the numbers for this game will be generated"
        );

        require(
            play[_idPlay].endPlayDate > block.timestamp,
            "the endgame date has already happened"
        );

        //**********/
        //debemos genera una nueva clave
        Ramdom.requestRandomWords();

        require(Ramdom.s_requestId() != 0, "seed cannot be 0");

        uint256 numberWinning = _generateWinningNumbers(
            _idPlay,
            Ramdom.s_requestId()
        );

        emit GenerateWinningNumbers(_idPlay, numberWinning, block.timestamp);

        return true;
    }

    function isfullCarton(uint256 _idPlay, uint256 _idCarton)
        public
        view
        returns (bool)
    {
        uint256[25] memory numberCarton = getAllNumersCartons(_idCarton);

        uint256[] memory numberPlayed = getNumbersPlayedByPlay(_idPlay);

        uint256 isWin = 0;

        for (uint256 i = 0; i < numberCarton.length; i++) {
            for (uint256 j = 0; j < numberPlayed.length; j++) {
                if (numberCarton[i] == numberPlayed[j]) {
                    isWin++;
                }
            }
        }

        if (isWin == 25) {
            return true;
        }

        return false;
    }

    function claimPrize(uint256 _idPlay, uint256 _idCarton)
        external
        returns (bool)
    {
        require(isPlay(_idPlay), "the id play not exists");

        require(
            play[_idPlay].endPlayDate < block.timestamp,
            "game close date has not occurred"
        );

        require(
            cartons[_idCarton].userOwner == msg.sender,
            "he is not the owner of the carton"
        );

        require(isfullCarton(_idPlay, _idCarton), "the carton is not a winer");

        USD.approve(address(this), play[_idPlay].amountUSDT);

        USD.transferFrom(
            address(this),
            cartons[_idCarton].userOwner,
            play[_idPlay].amountUSDT
        );

        emit ClaimPrize(_idPlay, _idCarton, msg.sender, block.timestamp);

        return true;
    }

    constructor(address usd, address _random) {
        owner[msg.sender] = true;

        USD = IERC20(usd);

        Ramdom = RandomNumberConsumer(_random);

        currentIdPlay.increment();

        currentIdCartons.increment();

        createAllNumberOfBingo();
    }
}

