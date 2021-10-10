<template>
  <div class="card-footer d-flex align-items-center">
    <p class="m-0 text-muted">
      Showing <span>{{ min }}</span> to <span>{{ max }}</span> of
      <span>{{ total }}</span> entries
    </p>
    <ul class="pagination m-0 ms-auto">
      <li class="page-item disabled">
        <button
          class="page-link"
          type="button"
          :disabled="current + 1 === 1"
          @click="handleClick(current - 1)"
        >
          <!-- Download SVG icon from http://tabler-icons.io/i/chevron-left -->
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="icon"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke-width="2"
            stroke="currentColor"
            fill="none"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
            <polyline points="15 6 9 12 15 18"></polyline>
          </svg>
          prev
        </button>
      </li>
      <li v-for="button of buttons" :key="button" class="page-item">
        <button
          class="page-link"
          :class="{ active: current + 1 === button }"
          type="button"
          @click="handleClick(button - 1)"
        >
          <template v-if="button === '...'">
            {{ button }}
          </template>
          <template v-else>
            {{ button }}
          </template>
        </button>
      </li>
      <li class="page-item">
        <button
          class="page-link"
          type="button"
          :disabled="current + 1 === lastPage"
          @click="handleClick(current + 1)"
        >
          next
          <!-- Download SVG icon from http://tabler-icons.io/i/chevron-right -->
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="icon"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke-width="2"
            stroke="currentColor"
            fill="none"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
            <polyline points="9 6 15 12 9 18"></polyline>
          </svg>
        </button>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  name: 'DataTablePagination',
  props: {
    total: {
      type: Number,
      required: true,
    },
    limit: {
      type: Number,
      required: true,
    },
    current: {
      type: Number,
      required: true,
    },
  },
  computed: {
    min() {
      return this.current === 0 ? 1 : this.current * this.limit + 1;
    },
    max() {
      return Math.min((this.current + 1) * this.limit, this.total);
    },
    lastPage() {
      return Math.ceil(this.total / this.limit);
    },
    buttons() {
      const { current, lastPage } = this;
      const buttons = [1];
      const center = [
        current - 2,
        current - 1,
        current,
        current + 1,
        current + 2,
      ];
      const filteredCenter = center.filter((p) => p > 1 && p < lastPage);
      const includeThreeLeft = current === 5;
      const includeThreeRight = current === lastPage - 4;
      const includeLeftDots = current > 5;
      const includeRightDots = current < lastPage - 4;

      if (includeThreeLeft) filteredCenter.unshift(2);
      if (includeThreeRight) filteredCenter.push(lastPage - 1);

      if (includeLeftDots) filteredCenter.unshift('...');
      if (includeRightDots) filteredCenter.push('...');

      buttons.push(...filteredCenter);
      if (lastPage !== 1) buttons.push(lastPage);

      return buttons;
    },
  },
  methods: {
    handleClick(page) {
      if (!isNaN(page)) {
        this.$emit('update:current', page);
      }
    },
  },
};
</script>
