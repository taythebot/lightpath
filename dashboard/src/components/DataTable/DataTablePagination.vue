<template>
  <div class="card-footer d-flex align-items-center">
    <p class="m-0 text-muted">
      Showing <span>{{ min }}</span> to <span>{{ max }}</span> of
      <span>{{ total }}</span> entries
    </p>
    <ul class="pagination m-0 ms-auto">
      <li class="page-item" :class="{ disabled: modelValue + 1 === 1 }">
        <button
          class="page-link"
          type="button"
          @click="handleClick(current - 1)"
        >
          <chevron-left-icon class="icon" />
          prev
        </button>
      </li>
      <li v-for="button of buttons" :key="button" class="page-item">
        <button
          class="page-link"
          :class="{ active: modelValue + 1 === button }"
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
      <li class="page-item" :class="{ disabled: modelValue + 1 === lastPage }">
        <button
          class="page-link"
          type="button"
          @click="handleClick(modelValue + 1)"
        >
          next
          <chevron-right-icon class="icon" />
        </button>
      </li>
    </ul>
  </div>
</template>

<script>
import { ChevronLeftIcon, ChevronRightIcon } from '@heroicons/vue/solid';

export default {
  name: 'DataTablePagination',
  components: {
    ChevronLeftIcon,
    ChevronRightIcon,
  },
  props: {
    modelValue: {
      type: Number,
      required: true,
    },
    total: {
      type: Number,
      required: true,
    },
    limit: {
      type: Number,
      required: true,
    },
  },
  computed: {
    min() {
      return this.modelValue === 0 ? 1 : this.modelValue * this.limit + 1;
    },
    max() {
      return Math.min((this.modelValue + 1) * this.limit, this.total);
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
        this.$emit('update:modelValue', page);
      }
    },
  },
};
</script>

<style scoped>
.icon {
  vertical-align: middle;
}
</style>
