import { DateTime } from 'luxon';

export default {
  install: (app) => {
    app.config.globalProperties.$luxon = DateTime;
    app.config.globalProperties.formatISO = (date) => {
      return DateTime.fromISO(date, { zone: 'utc' }).toLocaleString(
        DateTime.DATETIME_MED
      );
    };
  },
};
