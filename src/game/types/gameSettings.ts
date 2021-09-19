import { CardsInHandsView } from '../entities/cardsInHandsView.entity';
import { GameView } from '../entities/gameView.entity';

/**
 * Информация по настройкам игры
 */
export interface GameSettingsInfo {
  /**
   * Информация по игре
   */
  game: Partial<GameView>;

  /**
   * Карты на руках у пользователя
   */
  userCards: Partial<CardsInHandsView>[];

  opponent: {
    /**
     * Количество карт в руке оппонента
     */
    countCards: number;
    /**
     * Имя оппонента
     */
    name: string;

    numberPlayer: number;
  };
}
