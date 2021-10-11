// Services
import UserService from './users';
import ZoneService from './zones';

export default ($axios) => ({
  users: UserService($axios),
  zones: ZoneService($axios),
});
