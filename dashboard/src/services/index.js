// Services
import UserService from './user';
import ZoneService from './zone';

export default ($axios) => ({
  user: UserService($axios),
  zone: ZoneService($axios),
});
