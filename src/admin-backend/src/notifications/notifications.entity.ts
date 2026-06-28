import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  title!: string;

  @Column({type: 'text'})
  message!: string;

  @Column({default: 'order'})
  type!: string;

  @Column({default: false})
  IsRead!: boolean;

  @CreateDateColumn()
  createdAt!: Date;
}